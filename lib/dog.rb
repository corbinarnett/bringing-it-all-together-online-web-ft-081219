class Dog
  attr_accessor :name, :breed
  attr_reader :id

  def initialize(name:, breed:, id: nil)
    @name = name
    @breed = breed
    @id = id
  end

  def self.create_table
    sql = <<-SQL
      CREATE TABLE IF NOT EXISTS dogs (
        id INTEGER PRIMARY KEY,
        name TEXT,
        breed TEXT
      )
    SQL
    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = "DROP TABLE IF EXISTS dogs"
    DB[:conn].execute(sql)
  end

  def save
    if self.id
      self.update
    else
    sql = <<-SQL
        INSERT INTO dogs (name, breed)
        VALUES (?, ?)
      SQL
      DB[:conn].execute(sql, self.name, self.breed)
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
    end
    self
  end

  def self.create(attribute_hash)
    dog = Dog.new(attribute_hash)
      dog.save
      dog
  end

  def self.new_from_db(row)
    self.new(id: row[0], name: row[1], breed: row[2])
  end

  def self.find_by_id(id)
    sql = <<-SQL
      SELECT *
      FROM dogs
      WHERE id = ?
      LIMIT 1
    SQL

    DB[:conn].execute(sql,id).map do |row|
      self.new_from_db(row)
    end.first
  end

  def self.find_or_create_by(name:, breed:)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE name = ? AND breed = ?
      SQL
    dog = DB[:conn].execute(sql, name, breed)
    if dog.empty?
      dog = self.create(name: name, breed: breed)
    else
      dog_data = dog[0]
      dog = self.new(name: dog_data[1], breed: dog_data[2], id: dog_data[0])
    end
    dog
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE name = ?
      SQL
    row = DB[:conn].execute(sql, name)[0]
    self.find_or_create_by(name: row[1], breed: row[2])
  end

  def update
    sql = "UPDATE dogs SET name = ?, breed = ?  WHERE id = ?"
    DB[:conn].execute(sql, self.name, self.breed, self.id)
  end


end