module AdventOfCode2021
  module Day23
    extend self

    DAY = 23

    enum RoomType
      Wall
      Hallway
      Hallway_No_Stop
      Room_A
      Room_B
      Room_C
      Room_D
    end

    enum AmphipodaType
      Amber
      Bronze
      Copper
      Desert
    end

    struct Amphipoda
      getter id : Int32;
      getter type : AmphipodaType
      getter used_energy = 0
      getter position : Tuple(Int32, Int32)
      getter starting_position : Tuple(Int32, Int32)
      getter prev_position : Tuple(Int32, Int32) | Nil
      
      def initialize(@id, @type, @position); 
        @starting_position = @position
      end

      @@energies : StaticArray(Int32,4) = StaticArray[1, 10, 100, 1000]
      def energy : Int32
        @@energies[@type.to_i]
      end

      def room_to_occupy : RoomType
        RoomType.new(@type.to_i + RoomType::Room_A.to_i)
      end

      def find_possible_new_pos( burrow : Burrow) : Array(Tuple(Int32,Int32))
        new_positions = [] of Tuple(Int32,Int32)
        steps = [ {-1,0}, {1,0}, {0,-1}, {0,1} ]
        steps.each do | x_step, y_step|
          new_pos = { @position[0] + x_step, @position[1].y_step}
          if is_new_pos_valid?(new_pos ) 
        
            # step seems valid
            # TODO : check next step recursively
            # @prev_position = @position
            # @used_energy += @@energies[@type]
            # @position = {new_pos_x, new_pos_y}
            # if burrow.rooms[@position[0]][@position[1]] == RoomType::Hallway
            #   new_positions << @position
            # end
            # find_possible_new_pos burrow
          end           
        end
      end

      private def is_new_pos_valid?(new_pos ) : Bool
        !( !prev_position.nil? && new_pos == @prev_position #stepping back
            or get_room_type(burrow, new_pos) == RoomType::Wall # skip walls
            or burrow.amphipodas.any? { |amp| amp.position == new_pos && amp.id != @id }  # skip tiles having an ampiphoda
            )
      end

      def get_room_type(burrow : Burrow, pos_x : Int32, pos_y : Int32) : RoomType
        burrow.rooms[ pos_x][pos_y]
      end
    end

    struct Room
      getter type : RoomType
      getter position : Tuple(Int32, Int32)
      getter amphipoda : Amphipoda | Nil

      def initialize( @type, @position, @amphipoda = nil); end

      def has_amphipoda : Bool
        !amphipoda.nil?
      end

    end

    class Burrow
      getter rooms = [] of Array(RoomType);
      getter amphipodas = [] of Amphipoda;

      def initialize(@rooms, @amphipodas); end

      def initialize(str : String)
        parse_input str
      end

      def solved? : Bool
        false
      end
      
      def to_s(io : IO)
      end

      private def parse_input(input : String) 
        # puts "Input: #{input.lines}"
        lines = input.lines.map &.gsub(' ', '#').ljust(13, '#')
        #lines.each { |line| puts line }
        rooms = lines.map_with_index do |line,i|
          line.chars.map_with_index do |c,j|
            parse_room_char(c,i,j)
          end
        end
        @amphipodas = @amphipodas.sort { |a,b| a.type <=> b.type }
        rooms.each { |line| puts "#{line}"}
        amphipodas.each { |amp| puts "#{amp}"}
      end

      private def parse_room_char(c , i , j) : RoomType
        case c
        when '#'
          return RoomType::Wall
        when '.'
          case j
          when 3,5,7,9
            return RoomType::Hallway_No_Stop
          else
            return RoomType::Hallway
          end
        when 'A','B','C','D'
          amphipodas<<Amphipoda.new(amphipodas.size, AmphipodaType::Amber + (c-'A'), {i, j} )
          room_type = RoomType::Room_A + ( j - 3) // 2 # j could be 3,5,7,9
          return room_type
        end
        return RoomType::Wall
      end

      def solve1() 
        0
      end

      def solve2() 
        0
      end
    end

    def main
      burrow = Burrow.new(File.read "./src/day#{DAY}/input.txt")

      puts "Solutions of day#{DAY} : #{burrow.solve1} #{burrow.solve1}"
    end
  end
end
