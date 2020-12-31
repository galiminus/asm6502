module R6502
  X, Y = [ 'x', 'y' ]
  @@org = 0
  @@labels = {}
  @@mem = []

  class Label
    def self.[](value, size = 0)
      @@labels[value] = @@org
      @@org += size
    end
  end

  class Org
    def self.[](value) @@org = value; end
  end

  class Output
    def self.[](path, &block)
      File.open(path, 'w+') do |f|
        @@mem = []
        block.call
        f.write(@@mem.drop_while(&:nil?).reverse.drop_while(&:nil?).reverse.map(&:to_i).pack("c*"))
      end
    end
  end

  class Mem < Struct.new(:length, :value)
    def self.[]=(length, value)
      value = value.kind_of?(Symbol) ? @@labels[value] : value
      sprintf("%0#{value.size * 8 + 2}b", value)[2..-1].scan(/.{8}/).last(length).map { |i| i.to_i(2) }.reverse.each_with_index do |digit, index|
        @@mem[@@org + index] = digit
      end
      @@org += length
    end
  end

  {
    adc: { im: 0x69, zp: 0x65, zx: 0x75, ab: 0x6d, ax: 0x7d, ay: 0x79, ix: 0x61, iy: 0x71 },
    and: { im: 0x29, zp: 0x25, zx: 0x35, ab: 0x2d, ax: 0x3d, ay: 0x39, ix: 0x21, iy: 0x31 },
    sbc: { im: 0xe9, zp: 0xe5, zx: 0xf5, ab: 0xed, ax: 0xfd, ay: 0xf9, ix: 0xe1, iy: 0xf1 },
    asl: { ac: 0x0a, zp: 0x06, zx: 0x16, ab: 0x0e, ax: 0x1e }, bit: { zp: 0x24, ab: 0x2c },
    cmp: { im: 0xc9, zp: 0xc5, zx: 0xd5, ab: 0xcd, ax: 0xdd, ay: 0xd9, ix: 0xc1, iy: 0xd1 },
    cpx: { im: 0xe0, zp: 0xe4, ab: 0xec }, cpy: { im: 0xc0, zp: 0xc4, ab: 0xcc },
    dec: { zp: 0xc6, zx: 0xd6, ab: 0xce, ax: 0xde },
    ldx: { im: 0xa2, zp: 0xa6, zy: 0xb6, ab: 0xae, ay: 0xbe },
    ldy: { im: 0xa0, zp: 0xa4, zx: 0xb4, ab: 0xac, ax: 0xbc },
    eor: { im: 0x49, zp: 0x45, zx: 0x55, ab: 0x4d, ax: 0x5d, ay: 0x59, ix: 0x41, iy: 0x51 },
    inc: { zp: 0xe6, zx: 0xf6, ab: 0xee, ax: 0xfe },
    jmp: { ab: 0x4c, in: 0x6c }, sr:  { ab: 0x20 }, lsr: { ac: 0x4a, zx: 0x46, ab: 0x4e, ax: 0x5e },
    lda: { im: 0xa9, zp: 0xa5, zx: 0xb5, ab: 0xad, ax: 0xbd, ay: 0xb9, ix: 0xa1, iy: 0xb1 },
    ora: { im: 0x09, zp: 0x05, zx: 0x15, ab: 0x0d, ax: 0x1d, ay: 0x19, ix: 0x01, iy: 0x11 },
    rol: { ac: 0x2a, zp: 0x26, zx: 0x36, ab: 0x2e, ax: 0x3e },
    ror: { ac: 0x6a, zp: 0x66, zx: 0x76, ab: 0x6e, ax: 0x7e },
    sty: { zp: 0x84, zx: 0x94, ab: 0x8c }, stx: { zp: 0x86, zy: 0x96, ab: 0x8e },
    sta: { zp: 0x85, zx: 0x95, ab: 0x8d, ax: 0x9d, ay: 0x99, ix: 0x81, iy: 0x91 },
    bpl: { rl: 0x10 }, bmi: { rl: 0x30 }, bvc: { rl: 0x50 }, bne: { rl: 0xd0 },
    bvs: { rl: 0x70 }, bcc: { rl: 0x90 }, bcs: { rl: 0xb0 }, beq: { rl: 0xf0 },
    brk: 0x00, nop: 0xea, rti: 0x40, clc: 0x18, sec: 0x38, cli: 0x58, sei: 0x78, clv: 0xb8,
    cld: 0xd8, sed: 0xf8, txs: 0x9a, tsx: 0xba, pha: 0x48, rts: 0x60, pla: 0x68, php: 0x08,
    plp: 0x28, tax: 0xaa, txa: 0x8a, dex: 0xca, inx: 0xe8, tay: 0xa8, tya: 0x98, dey: 0x88, iny: 0xc8
  }.each do |opcode, modes|
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
        Mem[1] = opi
      end
    rescue => error
      raise ArgumentError.new("Unexpected error on '#{opcode} #{args.join(" ")}': #{error}")
    end
  end
end
