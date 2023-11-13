pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- editor sprites
function escape_binary_str(s)
 local out=""
 for i=1,#s do
  local c  = sub(s,i,i)
  local nc = ord(s,i+1)
  local pr = (nc and nc>=48 and nc<=57) and "00" or ""
  local v=c
  if(c=="\"") v="\\\""
  if(c=="\\") v="\\\\"
  if(ord(c)==0) v="\\"..pr.."0"
  if(ord(c)==10) v="\\n"
  if(ord(c)==13) v="\\r"
  out..= v
 end
 return out
end

printh(escape_binary_str(chr(peek(0,64*32))), "@clip")

__gfx__
011110000001000000010000000000005557c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17775100001710000017100000000000ffffa0000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000
17771000011711000100010000000000777570000000000000000000210000000000000000000000000000000000000000000000000000000000000000000000
17577100171775101700071000000000fb69a0000000000000000000320000000000000000000000000000000000000000000000000000000000000000000000
151577101577771001000100000000005d98b0000000000000000000430000000000000000000000000000000000000000000000000000000000000000000000
010151000157751000171000000000003e82d0000000000000000000540000000000000000000000000000000000000000000000000000000000000000000000
00001000001751000001000000000000222ee0000000000000000000620000000000000000000000000000000000000000000000000000000000000000000000
00000000000110000000000000000000000000000000000000000000750000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000820000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000980000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000ab0000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000bc0000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000cd0000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000de0000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000e10000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000fa0000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000221100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000332211100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000443333221000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555444332100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000666655544332210000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000777776665544332100000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000888222111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000999999882210000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000aaaaabbcde10000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000bbbcccdde100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000ccddddee1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000deee11000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000e11100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000ffe000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
88888888888888888222222288888888888888888888888888888888888888888888888899999999aaaaaaaa77777777ccccccccddddddddeeeeeeeeffffffff
88882888882222288200222288288888888888f88882828288888828888882888888888899999999aaaaaaaa70000007ccccccccddddddddeeeeeeeeffffffff
8882228888822288822022228222888888888fff8888888888888882888822288888888899999999aaaaaaaa70bbbb07ccccccccddddddddeeeeeeeeffffffff
882222288888288882202222888888888888fffff882888288882222288888888888888899999999aaaaaaaa70bbbb07ccccccccddddddddeeeeeeeeffffffff
88888888888888888220222288888888888f8fff8888888888828222888888888888888899999999aaaaaaaa70bbbb07ccccccccddddddddeeeeeeeeffffffff
88288828882888288200022282228888888f88f88882828288828828888822288888888899999999aaaaaaaa70bbbb07ccccccccddddddddeeeeeeeeffffffff
88222228882222288222222288288888888fff888888888888888888888882888888888899999999aaaaaaaa70000007ccccccccddddddddeeeeeeeeffffffff
88888888888888888222222288888888888888888888888888888888888888888888888899999999aaaaaaaa77777777ccccccccddddddddeeeeeeeeffffffff
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000333333400000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000666666666666666666666666666666666666666600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000603333333400000000000000000000000000000060000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000600555555540000000000000004bbbbbbb000000060000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000600555555540000000000000004bbbbbbb000000006000000000000000000000000000000000000000000
0000000000000000000000000000000000000000006000555555540000000000000004bbbbbbb000000006000000000000000000000000000000000000000000
00000000000000000000000000000000000000000060000555555400033333333bbbbbb55555bbbbbbbb00600000000000000000000000000000000000000000
00000000000000000000000000000000000000000600000555555400033333333bbbbbb555554bbbbbbb00600000000000000000000000000000000000000000
00000000000000000000000000000000000000000600000000000000033333333bbbbbb555554bbbbbbbb0060000000000000000000000000000000000000000
00000000000000000000000000000000000000006000000000000000033333333bbbbbb555554bbbbbbbb0060000000000000000000000000000000000000000
00000000000000000000000000000000000000006000000003333333355555555555555555554455555555006000000000000000000000000000000000000000
00000000000000000000000000000000000000060000000003333333345555555555555000044555555550006000000000000000000000000000000000000000
00000000000000000000000000000000000000060000000003333333345555555555555000004555555550000600000000000000000000000000000000000000
00000000000000000000000000000000000000600000000033333333345555555555555000004555555550000600000000000000000000000000000000000000
00000000000000000000000000000000000000600000000033333333345555555555555000004555555500000060000000000000000000000000000000000000
000000000000000000000000000000000000060033333333bbbbbbbb333333333bbbbbbb33333333000000033363333300000000000000000000000000000000
00000000000000000000000000000000000006033333333bbbbbbbb3333333333bbbbbbbb3333333300000043336333330000000000000000000000000000000
00000000000000000000000000000000000060033333333bbbbbbbb3333333333bbbbbbbb3333333300000443336333330000000000000000000000000000000
00000000000000000000000000000000000060033333333bbbbbbbb3333333333bbbbbbbb3333333300000443333633333000000000000000000000000000000
00000000000000000000000000000000000600333333333bbbbbbbb3333333333bbbbbbbb3333333300004444333633333000000000000000000000000000000
0000000000000000000000000000000000060033333333bbbbbbbbb3333333333bbbbbbbb3333333330004444333363333300000000000000000000000000000
0000000000000000000000000000000000600333333333bbbbbbbbb3333333333bbbbbbbb3333333330004444433363333330000000000000000000000000000
000000000000000000000000000033333363334555555533333333335555555555555555bbbbbbbbbb0000444555556555500000000000000000000000000000
0000000000000000000000000003333336333445555553333333333455555555555555554bbbbbbbbbb000444555556555000000000000000000000000000000
0000000000000000000000000003333336333444555553333333333455555555555555554bbbbbbbbbb000445555555655000000000000000000000000000000
0000000000000000000000000033333363334444555553333333333455555555555555554bbbbbbbbbb000045555555150000000000000000000000000000000
0000000000000000000000000333333363334444455533333333333445555555555555544bbbbbbbbbbb00077777771710000000000000000000000000000000
0000000000000000000000000333333633344444400033333333333440000000000000044bbbbbbbbbbb00070000010071000000000000000000000000000000
0000000000000000000000003333333633344444000033333333333400000000000000004bbbbbbbbbbb00007000170077100000000000000000000000000000
0000000000000000000000003333336333344444000033333333333400000000000000004bbbbbbbbbbb00007000010001000000000000000000000000000000
0000000000000000000000005555556555544440000bbbbbbbbbb333333333333bbbbbbbbbb33333333330000700001717600000000000000000000000000000
0000000000000000000000000555565555554440000bbbbbbbbbb333333333333bbbbbbbbbb33333333330000700000100700000000000000000000000000000
0000000000000000000000000055565555555440000bbbbbbbbbb333333333333bbbbbbbbbb33333333330000070000000760000000000000000000000000000
000000000000000000000000000065555555550000bbbbbbbbbbb333333333333bbbbbbbbbb33333333333000077777777770000000000000000000000000000
000000000000000000000000000060000000000000bbbbbbbbbbb333333333333bbbbbbbbbb33333333333000000000000006000000000000000000000000000
000000000000000000000000000600000000000000bbbbbbbbbbb333333333333bbbbbbbbbb33333333333000000000000006000000000000000000000000000
00000000000000000000000000060000000000000bbbbbbbbbbb3333333333333bbbbbbbbbbb3333333333300000000000000600000000000000000000000000
00000000000000000000000000600000000000000bbbbbbbbbbb3333333333333bbbbbbbbbbb3333333333300000000000000600000000000000000000000000
00000000000000000000000000600000000000000bbbbbbbbbbb3333333333333bbbbbbbbbbb3333333333300000000000000060000000000000000000000000
0000000000000000000000000600000000000000bbbbbbbbbbbb3333333333333bbbbbbbbbbb3333333333330000000000000060000000000000000000000000
00000000000000000000000006000000000000000555555555555555555555555555555555555555555555500000000000000006000000000000000000000000
00000000000000000000000060000000000000000555555555555555555555555555555555555555555555500000000000000006007770000000000000000000
00000000000000000000000060000000000000000055555555555555555555555555555555555555555555000000000000000000607070000000000000000000
00000000000000000000000666666666666666666666666666666666666666666666666666666666666666666666666666666666607070000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007070000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007770000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
08090a0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18191a1b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
28292a2b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
38393a3b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000292929292900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
