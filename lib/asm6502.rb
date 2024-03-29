require 'asm6502/opcodes'

module Asm6502
  X, Y = [ 'x', 'y' ]
  @@org = 0
  @@labels = {}
  @@mem = []

  def org=(value) @@org = value; end
  def org; @@org end

  def segment(output)
    @@mem = []
    yield
    output.write(@@mem.drop_while(&:nil?).reverse.drop_while(&:nil?).reverse.map(&:to_i).pack("c*"))
  end

  class Label
    def self.[](value, size = 0)
      @@labels[value] = @@org
      @@org += size
    end
  end

  class Mem
    def self.[]=(length, value)
      bytes_length = { byte: 1, word: 2, long: 4 }[length] || length
      value = value.kind_of?(Symbol) ? @@labels[value] : value
      bytes = sprintf("%0#{value.size * 8 + 2}b", value)[2..-1]
        .scan(/.{8}/)
        .last(bytes_length)
        .map { |i| i.to_i(2) }
        .reverse
        .each_with_index do |digit, index|
          @@mem[@@org + index] = digit
        end
      @@org += bytes_length
    end
  end

  OPCODES.each do |opcode, modes|
    define_method(opcode) do |*args|
      if args[0].nil? && modes.kind_of?(Integer)
        [ modes ]
      elsif modes[:ac] && args[0].nil?
        [ modes[:ac] ]
      elsif modes[:rl] && args[0].kind_of?(Symbol)
        [ modes[:rl], @@labels[args[0]] - @@org - 2 ]
      elsif modes[:im] && args[0].kind_of?(Integer) && args[0] < 0xff
        [ modes[:im], args[0] ]
      elsif modes[:zp] && args[0].kind_of?(Symbol) && @@labels[args[0]] < 0xff && args[1].nil?
        [ modes[:zp], @@labels[args[0]] ]
      elsif modes[:zx] && args[0].kind_of?(Symbol) && @@labels[args[0]] < 0xff && args[1].eql?(X)
        [ modes[:zx], @@labels[args[0]] ]
      elsif modes[:ab] && args[0].kind_of?(Symbol) && args[1].nil?
        [ modes[:ab], @@labels[args[0]] & 0xff, @@labels[args[0]] >> 8 & 0xff ]
      elsif modes[:ax] && args[0].kind_of?(Symbol) && args[1].eql?(X)
        [ modes[:ax], @@labels[args[0]] & 0xff, @@labels[args[0]] >> 8 & 0xff ]
      elsif modes[:ay] && args[0].kind_of?(Symbol) && args[1].eql?(Y)
        [ modes[:ay], @@labels[args[0]] & 0xff, @@labels[args[0]] >> 8 & 0xff ]
      elsif modes[:ix] && args[0].kind_of?(Array) && args[0].length == 2 && args[0][0].kind_of?(Symbol) && args[0][1].eql?(X) && args[1].nil?
        [ modes[:ix], @@labels[args[0][0]] & 0xff ]
      elsif modes[:iy] && args[0].kind_of?(Array) && args[0].length == 1 && args[0][0].kind_of?(Symbol) && args[1].eql?(Y)
        [ modes[:iy], @@labels[args[0][0]] & 0xff ]
      elsif modes[:in] && args[0].kind_of?(Array) && args[0].length == 1 && args[0][0].kind_of?(Symbol)
        [ modes[:in], @@labels[args[0][0]] & 0xff, @@labels[args[0][0]] >> 8 & 0xff ]
      else
        raise ArgumentError.new("No suitable mode found for '#{opcode} #{args.join(" ")}'")
      end.each do |opi|
        Mem[:byte] = opi
      end
    end
  end
end
