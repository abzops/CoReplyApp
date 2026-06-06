-- schema.sql
-- CoReply AI Supabase SQL Schema Configuration

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. Users table (synced from local Auth/AppGroup profiles)
create table public.users (
    id uuid primary key, -- Matches Auth UID when authenticated
    name text not null,
    age_range text not null,
    preferred_language text not null default 'English',
    communication_style text not null default 'Casual',
    subscription_tier text not null default 'free',
    daily_reply_count int not null default 0,
    daily_reset_at timestamptz not null default now(),
    created_at timestamptz not null default now()
);

-- Enable Row Level Security
alter table public.users enable row level security;

create policy "Users can view and edit their own user profile"
    on public.users
    for all
    using (auth.uid() = id);

-- 2. Relationship Profiles table
create table public.profiles (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users(id) on delete cascade,
    name text not null,
    relationship_type text not null,
    conversation_goal text not null,
    notes text,
    favorite_styles text[] not null default '{}',
    created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can manage their own relationship profiles"
    on public.profiles
    for all
    using (auth.uid() = user_id);

-- 3. Clipboard Messages table
create table public.messages (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users(id) on delete cascade,
    source_text text not null,
    detected_language text,
    profile_id uuid references public.profiles(id) on delete set null,
    created_at timestamptz not null default now()
);

alter table public.messages enable row level security;

create policy "Users can view and insert their own messages log"
    on public.messages
    for all
    using (auth.uid() = user_id);

-- 4. Generated Replies table
create table public.replies (
    id uuid primary key default gen_random_uuid(),
    message_id uuid not null references public.messages(id) on delete cascade,
    generated_text text not null,
    style text not null,
    score_overall double precision not null default 0.8,
    was_selected boolean not null default false,
    created_at timestamptz not null default now()
);

alter table public.replies enable row level security;

create policy "Users can access replies associated with their own messages"
    on public.replies
    for all
    using (
        exists (
            select 1 from public.messages
            where public.messages.id = public.replies.message_id
            and public.messages.user_id = auth.uid()
        )
    );

-- 5. Usage / Analytics events table
create table public.usage_events (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users(id) on delete cascade,
    event_type text not null,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

alter table public.usage_events enable row level security;

create policy "Users can log their own analytics events"
    on public.usage_events
    for all
    using (auth.uid() = user_id);

-- INDEXES for optimized query lookup performance
create index idx_profiles_user_id on public.profiles(user_id);
create index idx_messages_user_id on public.messages(user_id);
create index idx_replies_message_id on public.replies(message_id);
create index idx_usage_events_user_id on public.usage_events(user_id);

-- Automation: Resets daily count limits periodically (using postgres extensions if available, or called by edge triggers)
create or replace function public.reset_daily_reply_counts()
returns void as $$
begin
    update public.users
    set daily_reply_count = 0,
        daily_reset_at = now()
    where daily_reset_at < now() - interval '24 hours';
end;
$$ language plpgsql security definer;
