require 'rubygems'
require 'gosu'

class Sprite
  attr_accessor :x, :y, :kills, :speed, :fudge_factor

  def initialize(window, x, y, width, height, color, speed = 0, kills = false)
    @kills  = kills
    @window = window
    @width  = width
    @height = height
    @x      = x
    @y      = y
    @color  = color
    @speed  = speed

    if kills
      @fudge_factor = 7
    else
      @fudge_factor = -7
    end
  end

  def inside?(x, y)
    x.between?(@x + 5, r - 5) and y.between?(@y + 5, b - 5)
  end

  def left; @x; end
  def right; left + @width; end
  def top; @y; end
  def bottom; top + @height; end
  def r; right; end
  def b; bottom; end

  def update
    return if @speed == 0
    @x += @speed
    if @speed > 0 then                       # Moving to the right
      if @x > @window.width
        @x = 0 - @width
      end
    elsif @speed < 0 then
      @x = @window.width if @x < (0 - @width)
    end
  end

  def draw
    if @image then
      @image.draw(@x, @y, 1)
    else
      c = @color
    @window.draw_quad(@x, @y, c,
                      r,  @y, c,
                      r,  b,  c,
                      @x, b,  c)
    end
  end

  def check_x(other)
    r = self.right - fudge_factor
    l = self.left + fudge_factor

    (l.between?(other.left, other.right) ||
     r.between?(other.left, other.right) ||
     other.left.between?(l, r) ||
     other.right.between?(l, r))
  end

  def check_y(other)
    t = self.top + fudge_factor
    b = self.bottom - fudge_factor

    (t.between?(other.top, other.bottom) ||
     b.between?(other.top, other.bottom) ||
     other.top.between?(t, b) ||
     other.bottom.between?(t, b))
  end

  def collision(other)
    check_x(other) && check_y(other)
  end

  def move_left
    @x += -@width/2 unless @x == 0
  end

  def move_right
    @x += @width/2 unless r == @window.width
  end

  def move_up
    @y += -@height/2 unless @y == 0
  end

  def move_down
    @y += @height/2 unless b == @window.height
  end

  def stopped?
    @speed == 0
  end

  def set_image(image)
    @image = image
  end
end

class SpriteGroup
  attr_accessor :speed, :kills

  def initialize(window, x, y, width, height, color, speed, number, kills, spacing = nil)
    spacing = width/2 unless spacing
    @sprites = []
    @kills   = kills
    @speed   = speed

    number.times do
      @sprites << Sprite.new(window, x, y, width, height, color, speed, kills)

      if (x + width) > window.width then
        x = spacing - (window.width - x)
      else
        x += width + spacing
      end
    end
  end

  def update
    @sprites.each do |s|
      s.update
    end
  end

  def draw
    @sprites.each do |s|
      s.draw
    end
  end

  def collision(frog)
    return @sprites.any? { |s| s.collision(frog) }
  end

  def set_sprite_image(image)
    @sprites.each do |s|
      s.set_image(image)
    end
  end
end

class Frog < Sprite
  attr_accessor :image

  SIZE = 40;
  COLOR = Gosu::Color.new(0xff339900)

  def initialize(window)
    x = window.width/2 - SIZE/2
    y = window.height - SIZE

    @image = Gosu::Image.new(window, "assets/80sFrogger.png", false)
    super(window, x, y, SIZE, SIZE, COLOR)
  end

  def draw
    @image.draw(@x, @y, 1)
  end
end

class Cars < SpriteGroup
  def initialize(window, lane, lane_size, num_cars, speed, image)
    car_image = Gosu::Image.new(window, image, false)
    width = car_image.width
    height = car_image.height
    super(window, rand(window.width), lane * lane_size, width, height,
                    Gosu::Color::WHITE, speed, num_cars, true)
    set_sprite_image car_image
  end
end

class Trucks < SpriteGroup
  def initialize(window, lane, lane_size, num_trucks, speed, image)
    truck_image = Gosu::Image.new(window, image, false)
    width = truck_image.width
    height = truck_image.height
    super(window, rand(window.width), lane * lane_size, width, height,
                    Gosu::Color::WHITE, speed, num_trucks, true)
    set_sprite_image truck_image
  end
end

class Turtles < SpriteGroup
  IMAGE_PATH = "assets/turtle.png"

  def initialize(window, lane, lane_size, count, speed)
    turtle_image = Gosu::Image.new(window, IMAGE_PATH, false)
    width = turtle_image.width
    height = turtle_image.height
    super(window, rand(window.width), lane * lane_size, width, height,
          Gosu::Color::WHITE, speed, count, false)
    set_sprite_image turtle_image
  end
end

class Logs < SpriteGroup
  IMAGE_PATH = "assets/log.png"

  def initialize(window, lane, lane_size, count, speed)
    log_image = Gosu::Image.new(window, IMAGE_PATH, false)
    width = log_image.width
    height = log_image.height
    super(window, rand(window.width), lane * lane_size, width, height,
          Gosu::Color::WHITE, speed, count, false, 100)

    set_sprite_image log_image
  end
end

class Frogger < Gosu::Window
  attr_accessor :window_x

  SPACE = Frog::SIZE / 2
  LANE = Frog::SIZE + SPACE

  def initialize
    @window_x = 800
    @window_y = 640
    super(@window_x, @window_y, false)

    @font = Gosu::Font.new(self, Gosu::default_font_name, 100)
    setup
    @paused = false

  end

  def setup
    @text = ""

    @frog = Frog.new(self)
    fs = Frog::SIZE

    @bg = []
    @bg << Sprite.new(self, 0, 0, @window_x, @window_y / 2, Gosu::Color.new(0xff0066cc))
    @bg << Sprite.new(self, 0, 10 * LANE, @window_x, fs, Gosu::Color::GRAY)
    @bg << Sprite.new(self, 0, 5 * LANE, @window_x, fs, Gosu::Color::GRAY)

    @enemies = []
    @enemies << Cars.new(self, 9, LANE, 3, 1.5, "assets/orange_car.png")
    @enemies << Trucks.new(self, 8, LANE, 1, 0.5, "assets/blue_truck_r.png")
    @enemies << Cars.new(self, 7, LANE, 4, -1.5, "assets/yellow_car.png")
    @enemies << Trucks.new(self, 6, LANE, 2, -0.5, "assets/blue_truck.png")
    @enemies << Logs.new(self, 4, LANE, 2, -0.5)
    @enemies << Turtles.new(self, 3, LANE, 5, -1)
    @enemies << Logs.new(self, 2, LANE, 2, 0.5)
    @enemies << Turtles.new(self, 1, LANE, 5, 1)

    @goal = Sprite.new(self, 0, 0, @window_x, fs, Gosu::Color.new(0xff660066),
                       0, true)
  end

  def update
    @frog.speed = 0

    unless @paused
      @enemies.each do |enemy|
        enemy.update


        if enemy.collision(@frog) then
          if enemy.kills then
            @paused = true
            @text = "SPLAT"
            break
          else
            @frog.speed = enemy.speed
          end
        end
      end

      if @frog.y == 0
        @paused = true
        @text = "YOU WIN"
      end

      # Frog isn't on a turtle or log
      if @frog.stopped? and @frog.y.between?(Frog::SIZE, LANE * 4 + SPACE) then
        @text = "SPLASH"
        @paused = true
      end

      @frog.update
    end
  end

  def draw
    [@bg, @enemies, @goal, @frog].flatten.each { |o| o.draw }
    font_color = Gosu::Color::WHITE
    case @text
      when "SPLAT"
      font_color = Gosu::Color::RED
      when "SPLASH"
      font_color = Gosu::Color::BLUE
      when "YOU WIN"
      font_color = Gosu::Color::YELLOW
    end
    @font.draw_rel(@text, @window_x / 2, @window_y / 2, 1, 0.5, 0.5, 1.5, 1.5,
                   font_color)
  end

  def button_down(id)
    case id
    when Gosu::KbSpace
      @paused = !@paused
      return
    when Gosu::KbLeft
      @frog.move_left
    when Gosu::KbRight
      @frog.move_right
    when Gosu::KbDown
      @frog.move_down
    when Gosu::KbUp
      @frog.move_up
    when Gosu::KbR, Gosu::KbO
      @paused = true
      setup
      @paused = false
    end
  end
end

Frogger.new.show
