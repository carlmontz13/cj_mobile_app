-- Materials table for storing AI-generated instructional content
CREATE TABLE IF NOT EXISTS materials (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    class_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    language_code TEXT NOT NULL DEFAULT 'en',
    simplified_content TEXT,
    standard_content TEXT,
    advanced_content TEXT,
    selected_content_type TEXT CHECK(selected_content_type IN ('simplified', 'standard', 'advanced')),
    selected_content TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT 1,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

-- Index for better query performance
CREATE INDEX IF NOT EXISTS idx_materials_class_id ON materials(class_id);
CREATE INDEX IF NOT EXISTS idx_materials_created_by ON materials(created_by);
CREATE INDEX IF NOT EXISTS idx_materials_language ON materials(language_code);
CREATE INDEX IF NOT EXISTS idx_materials_created_at ON materials(created_at);

-- Trigger to update the updated_at timestamp
CREATE TRIGGER IF NOT EXISTS update_materials_updated_at
    AFTER UPDATE ON materials
    FOR EACH ROW
BEGIN
    UPDATE materials SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;
