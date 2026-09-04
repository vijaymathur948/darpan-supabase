-- Create backlog table
CREATE TABLE IF NOT EXISTS backlog (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_name VARCHAR(255) NOT NULL,
  description TEXT,
  priority VARCHAR(50) NOT NULL DEFAULT 'P2' CHECK (priority IN ('P1', 'P2', 'P3')),
  status VARCHAR(50) NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'In Progress', 'Done')),
  due_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create RLS policies
ALTER TABLE backlog ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read all backlog items
CREATE POLICY "Allow authenticated users to read backlog"
  ON backlog
  FOR SELECT
  TO authenticated
  USING (true);

-- Allow authenticated users to create backlog items
CREATE POLICY "Allow authenticated users to create backlog"
  ON backlog
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Allow authenticated users to update backlog items
CREATE POLICY "Allow authenticated users to update backlog"
  ON backlog
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Allow authenticated users to delete backlog items
CREATE POLICY "Allow authenticated users to delete backlog"
  ON backlog
  FOR DELETE
  TO authenticated
  USING (true);

-- Create index for better query performance
CREATE INDEX idx_backlog_status ON backlog(status);
CREATE INDEX idx_backlog_priority ON backlog(priority);
CREATE INDEX idx_backlog_due_date ON backlog(due_date);
