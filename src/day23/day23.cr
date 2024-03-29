module AdventOfCode2021
  extend self

  module Day23
    extend self
    DAY = 23

    WALL   = '#'.bytes[0]
    EMPTY  = '.'.bytes[0]
    AMBER  = 'A'.bytes[0]
    BRONZE = 'B'.bytes[0]
    COPPER = 'C'.bytes[0]
    DESERT = 'D'.bytes[0]

    def is_type?(t : UInt8) : Bool
      case t
      when AMBER..DESERT then true
      else                    false
      end
    end

    class Room
      DEFAULT_SIZE = 2
      OTHER_SIZE   = 4
      getter size = DEFAULT_SIZE
      getter type
      getter amphipodas

      def initialize(@type : UInt8, @amphipodas : Array(UInt8) = Array(UInt8).new(DEFAULT_SIZE))
        raise Exception.new("Type can be only AMBER, BRONZE, COPPER or DESERT") if @type < AMBER || DESERT < @type
        raise Exception.new("Amphipods can be only AMBER, BRONZE, COPPER or DESERT") if @amphipodas.any? { |a| a < AMBER || DESERT < a }
        raise Exception.new("Cannot add more amphipods then #{@size}") if @amphipodas.size > @size
      end

      def initialize(@size : Int32, @type : UInt8, @amphipodas : Array(UInt8) = Array(UInt8).new(@size))
        raise Exception.new("Size can be only 2 or 4") if @size != 2 && @size != 4
        raise Exception.new("Type can be only AMBER, BRONZE, COPPER or DESERT") if @type < AMBER || DESERT < @type
        raise Exception.new("Amphipods can be only AMBER, BRONZE, COPPER or DESERT") if @amphipodas.any? { |a| a < AMBER || DESERT < a }
        raise Exception.new("Cannot add more amphipods then #{@size}") if @amphipodas.size > @size
      end

      def clone
        Room.new(@size, @type, @amphipodas.clone)
      end

      def can_pop? : Bool
        !@amphipodas.empty? && @amphipodas.any? &.!= @type
      end

      def pop : Tuple(UInt8, Int32) | Nil
        return nil if !can_pop?
        {@amphipodas.pop, @size - @amphipodas.size}
      end

      def can_push?(amp : UInt8) : Bool
        @type == amp && @amphipodas.size < @size && @amphipodas.all? &.== @type
      end

      # Returns the number of steps
      def push(amp : UInt8) : Int32 | Nil
        return nil if !can_push?(amp)
        @amphipodas << amp
        @size - @amphipodas.size + 1
      end

      def solved? : Bool
        @amphipodas.size == @size && @amphipodas.all? &.== @type
      end
    end

    class Burrow
      include AdventOfCode2021::Day23
      getter hallway = StaticArray(UInt8, 11).new(EMPTY)
      getter rooms = StaticArray(Room, 4).new { |i| AdventOfCode2021::Day23::Room.new(AdventOfCode2021::Day23::AMBER + i.to_u8) }
      getter used_energy = 0
      getter solutions = Hash(String, Burrow).new
      getter min_energy : Int32 | Nil = nil
      # shapshot is for debugging.
      getter snapshot : Burrow | Nil = nil
      getter room_size = 2
      @@energies : StaticArray(Int32, 4) = StaticArray[1, 10, 100, 1000]

      def initialize; end

      def initialize(@hallway, @rooms, @room_size, @solutions, snapshot); end

      def clone
        Burrow.new(@hallway.clone, @rooms.clone, @room_size, @solutions, @snapshot.clone)
      end

      def initialize(str : String)
        parse_input(str)
      end

      private def parse_input(input : String)
        lines = input.lines
        @hallway.fill { |i| lines[1].byte_at i + 1 }
        @room_size = lines.size - 3
        raise Exception.new("Bad number of input lines") if @room_size != Room::DEFAULT_SIZE && @room_size != Room::OTHER_SIZE
        parse_rooms lines
      end

      private def parse_rooms(lines)
        lines = lines[2..(lines.size - 2)].reverse
        (0...@rooms.size).each do |i|
          amps = lines.map(&.byte_at(3 + 2 * i)).select(&.!= EMPTY)
          @rooms[i] = Room.new(@room_size, AMBER + i.to_i8, amps)
        end
      end

      def to_s(io : IO) : Nil
        io << "#############\n"
        io << "#"
        @hallway.each { |h| io.write_byte h }
        io << "#\n"
        print_rooms io
        io << "  #########"
      end

      private def print_rooms(io)
        (0...@room_size).each do |i|
          io << (i == 0 ? "##" : "  ")
          @rooms.each do |room|
            io << "#"
            if room.amphipodas.size > @room_size - i - 1
              # pp! @room_size, i, room
              io.write_byte room.amphipodas[@room_size - i - 1]
            else
              io.write_byte EMPTY
            end
          end
          io << "##" if i == 0
          io << "#\n"
        end
      end

      private def first_line_to_s(io)
        io << "##"
        (0...@rooms.size).each do |i|
          io << "#"
          if @rooms[i].amphipodas.size > 1
            io.write_byte @rooms[i].amphipodas[1]
          else
            io.write_byte EMPTY
          end
        end
        io << "###\n"
      end

      def solved? : Bool
        @rooms.all? &.solved?
      end

      def solve : Int32?
        # puts "Burrow :\n#{self}"
        # puts "Press enter...  "
        # gets

        if solved?
          return @used_energy + (@min_energy || 0)
        end

        # check cached solved or not solvable burrows
        cached = @solutions[to_s]?
        if !cached.nil?
          me = cached.min_energy
          return me.nil? ? nil : @used_energy + me
        end

        iterate_over_amphipods
        # cache solved state
        @solutions[to_s] = self
        me = @min_energy
        return me.nil? ? nil : @used_energy + (@min_energy || 0)
      end

      private def iterate_over_amphipods
        iterate_over_amphipods_in_hallway
        iterate_over_amphipods_in_rooms
      end

      private def iterate_over_amphipods_in_hallway
        @hallway.each_with_index do |h, i|
          if h != EMPTY
            check_next_movement_h2r i
          end
        end
      end

      private def iterate_over_amphipods_in_rooms
        @rooms.each_with_index do |room, i|
          if room.can_pop?
            check_next_movement_r2h room, i
          end
        end
      end

      # check an amphipod's possible movements from hallway to room
      private def check_next_movement_h2r(idx : Int32)
        check_next_movement_h2r idx, ((idx - 1)..2), -1
        check_next_movement_h2r idx, ((idx + 1)..(@hallway.size - 3)), +1
      end

      private def check_next_movement_h2r(idx : Int32, range : Range, stepby : Int32)
        range.step(stepby) do |i|
          break if @hallway[i] != EMPTY
          if Burrow.is_entry? i
            room_ind = Burrow.hallway_index_to_room i
            if @rooms[room_ind].can_push? @hallway[idx]
              next_burrow_moving_h2r idx, room_ind
            end
          end
        end
      end

      # check an amphipod's possible movements from room to hallway
      private def check_next_movement_r2h(room : Room, idx : Int32)
        h = Burrow.room_index_to_hallway idx
        check_next_movement_r2h idx, ((h - 1)..0), -1
        check_next_movement_r2h idx, ((h + 1)..(@hallway.size - 1)), +1
      end

      private def check_next_movement_r2h(idx, range, stepby)
        range.step(stepby) do |i|
          break if @hallway[i] != EMPTY
          if Burrow.is_not_entry? i
            next_burrow_moving_r2h idx, i
          end
        end
      end

      private def next_burrow_moving_r2h(room_idx, h_idx)
        new_burrow = self.clone
        new_burrow.move_amp_r2h(room_idx, h_idx)
        solve_next_burrow new_burrow
      end

      private def next_burrow_moving_h2r(h_idx, room_idx)
        new_burrow = self.clone
        new_burrow.move_amp_h2r(h_idx, room_idx)
        solve_next_burrow new_burrow
      end

      # move amp from room to hallway
      def move_amp_r2h(from_idx : Int32, to_idx : Int32)
        ret = @rooms[from_idx].pop
        if !ret.nil?
          amp, steps = ret
          steps += (Burrow.room_index_to_hallway(from_idx) - to_idx).abs
          @used_energy += Burrow.energy_of(amp)*steps
          @hallway[to_idx] = amp
        end
      end

      # move amp from hallway to room
      def move_amp_h2r(from_idx : Int32, to_idx : Int32)
        amp = self.hallway[from_idx]
        self.hallway[from_idx] = EMPTY
        steps = @rooms[to_idx].push amp
        if !steps.nil?
          steps += (Burrow.room_index_to_hallway(to_idx) - from_idx).abs
          @used_energy += Burrow.energy_of(amp)*(steps)
        end
      end

      private def solve_next_burrow(new_burrow)
        me = @min_energy
        next_me = new_burrow.solve
        if !next_me.nil? && (me.nil? || !me.nil? && next_me < me)
          @snapshot = new_burrow
          @min_energy = next_me
        end
      end

      def print_snapshots
        puts self
        puts "used_energy: #{used_energy}, min_energy: #{min_energy}"
        snapshot = @snapshot
        if !snapshot.nil?
          snapshot.print_snapshots
        end
      end

      def self.room_index_to_hallway(r : Int32) : Int32
        2 + r * 2
      end

      def self.hallway_index_to_room(h : Int32) : Int32
        (h - 2) // 2
      end

      def self.is_entry?(h : Int32) : Bool
        case h
        when 2, 4, 6, 8 then true
        else                 false
        end
      end

      def self.is_not_entry?(h : Int32) : Bool
        (0..10).includes?(h) && !Burrow.is_entry?(h)
      end

      def self.energy_of(amp : UInt8)
        @@energies[(amp - AMBER).to_i]
      end
    end

    def main
      burrow1 = Burrow.new(File.read "./src/day#{DAY}/input.txt")
      burrow2 = Burrow.new(File.read "./src/day#{DAY}/input2.txt")

      puts "Solutions of day#{DAY} : #{burrow1.solve} #{burrow2.solve}"
    end
  end
end
