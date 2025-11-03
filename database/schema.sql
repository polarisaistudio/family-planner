-- Family Planner Database Schema
-- Execute this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    language_preference TEXT DEFAULT 'en',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Groups table (for family sharing)
CREATE TABLE IF NOT EXISTS public.user_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    owner_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Group Members table
CREATE TABLE IF NOT EXISTS public.group_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID REFERENCES public.user_groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member', -- 'owner', 'admin', 'member'
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(group_id, user_id)
);

-- Todos table
CREATE TABLE IF NOT EXISTS public.todos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    todo_date DATE NOT NULL,
    todo_time TIME,
    priority INTEGER DEFAULT 3, -- 1=urgent, 2=high, 3=medium, 4=low, 5=none
    type TEXT DEFAULT 'other', -- 'appointment', 'work', 'shopping', 'personal', 'other'
    status TEXT DEFAULT 'pending', -- 'pending', 'in_progress', 'completed', 'cancelled'
    location TEXT,
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    notification_enabled BOOLEAN DEFAULT true,
    notification_minutes_before INTEGER DEFAULT 30,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Subtasks table (for nested tasks)
CREATE TABLE IF NOT EXISTS public.subtasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_todo_id UUID REFERENCES public.todos(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT false,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Shopping Items table (specific for shopping todos)
CREATE TABLE IF NOT EXISTS public.shopping_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    todo_id UUID REFERENCES public.todos(id) ON DELETE CASCADE,
    item_name TEXT NOT NULL,
    quantity INTEGER DEFAULT 1,
    unit TEXT,
    checked BOOLEAN DEFAULT false,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Appointment Notes table (specific for appointment todos)
CREATE TABLE IF NOT EXISTS public.appointment_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    todo_id UUID REFERENCES public.todos(id) ON DELETE CASCADE,
    note_type TEXT DEFAULT 'general', -- 'question', 'symptom', 'medication', 'general'
    content TEXT NOT NULL,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Shared Todos table (for sharing between users)
CREATE TABLE IF NOT EXISTS public.shared_todos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    todo_id UUID REFERENCES public.todos(id) ON DELETE CASCADE,
    shared_with_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    permission_level TEXT DEFAULT 'view', -- 'view', 'edit'
    shared_by_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(todo_id, shared_with_user_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_todos_user_id ON public.todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_date ON public.todos(todo_date);
CREATE INDEX IF NOT EXISTS idx_todos_status ON public.todos(status);
CREATE INDEX IF NOT EXISTS idx_subtasks_parent ON public.subtasks(parent_todo_id);
CREATE INDEX IF NOT EXISTS idx_shopping_items_todo ON public.shopping_items(todo_id);
CREATE INDEX IF NOT EXISTS idx_appointment_notes_todo ON public.appointment_notes(todo_id);
CREATE INDEX IF NOT EXISTS idx_shared_todos_user ON public.shared_todos(shared_with_user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user ON public.group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_group ON public.group_members(group_id);

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subtasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shopping_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointment_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shared_todos ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can view their own data"
    ON public.users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own data"
    ON public.users FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert their own data"
    ON public.users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- RLS Policies for todos table
CREATE POLICY "Users can view their own todos"
    ON public.todos FOR SELECT
    USING (auth.uid() = user_id OR auth.uid() IN (
        SELECT shared_with_user_id FROM public.shared_todos WHERE todo_id = todos.id
    ));

CREATE POLICY "Users can insert their own todos"
    ON public.todos FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own todos"
    ON public.todos FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own todos"
    ON public.todos FOR DELETE
    USING (auth.uid() = user_id);

-- RLS Policies for subtasks table
CREATE POLICY "Users can view subtasks of their todos"
    ON public.subtasks FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.todos WHERE todos.id = subtasks.parent_todo_id AND todos.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert subtasks to their todos"
    ON public.subtasks FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.todos WHERE todos.id = subtasks.parent_todo_id AND todos.user_id = auth.uid()
    ));

CREATE POLICY "Users can update subtasks of their todos"
    ON public.subtasks FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM public.todos WHERE todos.id = subtasks.parent_todo_id AND todos.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete subtasks of their todos"
    ON public.subtasks FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM public.todos WHERE todos.id = subtasks.parent_todo_id AND todos.user_id = auth.uid()
    ));

-- RLS Policies for shopping_items table
CREATE POLICY "Users can manage shopping items of their todos"
    ON public.shopping_items FOR ALL
    USING (EXISTS (
        SELECT 1 FROM public.todos WHERE todos.id = shopping_items.todo_id AND todos.user_id = auth.uid()
    ));

-- RLS Policies for appointment_notes table
CREATE POLICY "Users can manage appointment notes of their todos"
    ON public.appointment_notes FOR ALL
    USING (EXISTS (
        SELECT 1 FROM public.todos WHERE todos.id = appointment_notes.todo_id AND todos.user_id = auth.uid()
    ));

-- RLS Policies for shared_todos table
CREATE POLICY "Users can view todos shared with them"
    ON public.shared_todos FOR SELECT
    USING (auth.uid() = shared_with_user_id OR auth.uid() = shared_by_user_id);

CREATE POLICY "Users can share their own todos"
    ON public.shared_todos FOR INSERT
    WITH CHECK (auth.uid() = shared_by_user_id);

CREATE POLICY "Users can delete shares they created"
    ON public.shared_todos FOR DELETE
    USING (auth.uid() = shared_by_user_id);

-- RLS Policies for user_groups table
CREATE POLICY "Users can view groups they belong to"
    ON public.user_groups FOR SELECT
    USING (auth.uid() = owner_id OR auth.uid() IN (
        SELECT user_id FROM public.group_members WHERE group_id = user_groups.id
    ));

CREATE POLICY "Users can create groups"
    ON public.user_groups FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Group owners can update their groups"
    ON public.user_groups FOR UPDATE
    USING (auth.uid() = owner_id);

CREATE POLICY "Group owners can delete their groups"
    ON public.user_groups FOR DELETE
    USING (auth.uid() = owner_id);

-- RLS Policies for group_members table
CREATE POLICY "Users can view members of their groups"
    ON public.group_members FOR SELECT
    USING (auth.uid() = user_id OR EXISTS (
        SELECT 1 FROM public.user_groups WHERE user_groups.id = group_members.group_id AND user_groups.owner_id = auth.uid()
    ));

CREATE POLICY "Group owners can add members"
    ON public.group_members FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.user_groups WHERE user_groups.id = group_members.group_id AND user_groups.owner_id = auth.uid()
    ));

CREATE POLICY "Group owners can remove members"
    ON public.group_members FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM public.user_groups WHERE user_groups.id = group_members.group_id AND user_groups.owner_id = auth.uid()
    ));

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_groups_updated_at BEFORE UPDATE ON public.user_groups
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_todos_updated_at BEFORE UPDATE ON public.todos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subtasks_updated_at BEFORE UPDATE ON public.subtasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_appointment_notes_updated_at BEFORE UPDATE ON public.appointment_notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to create user profile automatically after signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, full_name)
    VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create user profile on signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
