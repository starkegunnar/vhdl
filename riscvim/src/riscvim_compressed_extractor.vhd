library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_riscvim;
use lib_riscvim.riscvim_pkg.all;

entity riscvim_compressed_extractor is
  port (
    instr_in          : in  std_logic_vector(31 downto 0);
    instr_out         : out std_logic_vector(31 downto 0);
    compressed_instr  : out std_logic;
    illegal_instr     : out std_logic
  );
end entity;

architecture rtl of riscvim_compressed_extractor is

begin

  compressed_instr <= nand instr_in(1 downto 0);

  p_extract : process(instr_in)
  begin
    instr_out     <= (others => '0');
    illegal_instr <= '0';

    case instr_in(1 downto 0) is
    when c_opcode_c0 => -- "00"
      case instr_in(15 downto 13) is
      when "000" => -- C.ADDI4SPN
        instr_out <= (
          31 downto 30  => "00",
          29 downto 26  => instr_in(10 downto 7),
          25 downto 24  => instr_in(12 downto 11),
          23            => instr_in(5),
          22            => instr_in(6),
          21 downto 10  => "000001000001",
           9 downto  7  => instr_in(4 downto 2),
           6 downto  0  => c_opcode_op_imm
        );
        illegal_instr <= nor instr_in(12 downto 5);
      when "010" => -- C.LW
        instr_out <= (
          31 downto 27  => "00000",
          26            => instr_in(5),
          25 downto 23  => instr_in(12 downto 10),
          22            => instr_in(6),
          21 downto 18  => "0001",
          17 downto 15  => instr_in(9 downto 7),
          14 downto 10  => "01001",
           9 downto  7  => instr_in(4 downto 2),
           6 downto  0  => c_opcode_load
        );
      when "110" => -- C.SW
        instr_out <= (
          31 downto 27  => "00000",
          26            => instr_in(5),
          25            => instr_in(12),
          24 downto 23  => "01",
          22 downto 20  => instr_in(4 downto 2),
          19 downto 18  => "01",
          17 downto 15  => instr_in(9 downto 7),
          14 downto 12  => "010",
          11 downto 10  => instr_in(11 downto 10),
           9            => instr_in(6),
           8 downto  7  => "00",
           6 downto  0  => c_opcode_store
        );
      when others =>
        illegal_instr <= '1';
      end case;
    when c_opcode_c1 =>
      case instr_in(15 downto 13) is
      when "000" => -- C.ADDI, C.NOP
        instr_out <= (
          31 downto 25  => instr_in(12),
          24 downto 20  => instr_in(6 downto 2),
          19 downto 15  => instr_in(11 downto 7),
          14 downto 12  => "000",
          11 downto  7  => instr_in(11 downto 7),
           6 downto  0  => c_opcode_op_imm
        );
        illegal_instr <= nor instr_in(12 downto 5);
      when "001" | "101" => -- C.JAL, C.J
        instr_out <= (
          31            => instr_in(12),
          30            => instr_in(8),
          29 downto 28  => instr_in(10 downto 9),
          27            => instr_in(6),
          26            => instr_in(7),
          25            => instr_in(2),
          24            => instr_in(11),
          23 downto 21  => instr_in(5 downto 3),
          20 downto 12  => instr_in(12),
          11 downto  8  => "0000",
           7            => not instr_in(15),
           6 downto  0  => c_opcode_jal
        );
      when "010" => -- C.LI
        instr_out <= (
          31 downto 25  => instr_in(12),
          24 downto 20  => instr_in(6 downto 2),
          19 downto 12  => '0',
          11 downto 7   => instr_in(11 downto 7),
           6 downto  0  => c_opcode_op_imm
        );
      when "011" => -- C.ADDI
        if (instr_in(12) & instr_in(6 downto 2)) = 6x"00" then
          illegal_instr <= '1';
        elsif instr_in(11 downto 7) = 5x"02" then
          -- C.ADDI16SP
          instr_out <= (
            31 downto 29  => instr_in(12),
            28 downto 27  => instr_in(4 downto 3),
            26            => instr_in(5),
            25            => instr_in(2),
            24            => instr_in(6),
            23 downto  7  => "00000001000000010",
             6 downto  0  => c_opcode_op_imm
          );
        else
          -- C.LUI
          instr_out <= (
            31 downto 17  => instr_in(12),
            16 downto 12  => instr_in(6 downto 2),
            11 downto  7  => instr_in(11 downto 7),
             6 downto  0  => c_opcode_lui
          );
        end if;
      when "100" =>
        case instr_in(11 downto 10) is
        when "00" | "01" => -- C.SRLI, C.SRAI
          instr_out <= (
            31            => '0',
            30            => instr_in(10),
            29 downto 25  => '0',
            24 downto 20  => instr_in(6 downto 2),
            19 downto 18  => "01",
            17 downto 15  => instr_in(9 downto 7),
            14 downto 10  => "10101",
             9 downto  7  => instr_in(9 downto 7),
             6 downto  0  => c_opcode_op_imm
          );
          illegal_instr <= instr_in(12);
        when "10" => -- C.ANDI
          instr_out <= (
            31 downto 25  => instr_in(12),
            24 downto 20  => instr_in(6 downto 2),
            19 downto 18  => "01",
            17 downto 15  => instr_in(9 downto 7),
            14 downto 10  => "11101",
             9 downto  7  => instr_in(9 downto 7),
             6 downto  0  => c_opcode_op_imm
          );
        when "11" =>
          case std_logic_vector'(instr_in(12) & instr_in(6 downto 5)) is
          when "000" => -- C.SUB
            instr_out <= (
              31 downto 23  => "010000001",
              22 downto 20  => instr_in(4 downto 2),
              19 downto 18  => "01",
              17 downto 15  => instr_in(9 downto 7),
              14 downto 10  => "00001",
               9 downto  7  => instr_in(9 downto 7),
               6 downto  0  => c_opcode_op
            );
          when "001" => -- C.XOR
            instr_out <= (
              31 downto 23  => "000000001",
              22 downto 20  => instr_in(4 downto 2),
              19 downto 18  => "01",
              17 downto 15  => instr_in(9 downto 7),
              14 downto 10  => "10001",
               9 downto  7  => instr_in(9 downto 7),
               6 downto  0  => c_opcode_op
            );
          when "010" => -- C.OR
            instr_out <= (
              31 downto 23  => "000000001",
              22 downto 20  => instr_in(4 downto 2),
              19 downto 18  => "01",
              17 downto 15  => instr_in(9 downto 7),
              14 downto 10  => "11001",
               9 downto  7  => instr_in(9 downto 7),
               6 downto  0  => c_opcode_op
            );
          when "011" => -- C.AND
            instr_out <= (
              31 downto 23  => "000000001",
              22 downto 20  => instr_in(4 downto 2),
              19 downto 18  => "01",
              17 downto 15  => instr_in(9 downto 7),
              14 downto 10  => "11101",
               9 downto  7  => instr_in(9 downto 7),
               6 downto  0  => c_opcode_op
            );
          when others =>
            illegal_instr <= '1';
          end case;
        when others =>
          illegal_instr <= '1';
        end case;
      when "110" | "111" => -- C.BEQZ, C.BNEZ
        instr_out <= (
          31 downto 28  => instr_in(12),
          27 downto 26  => instr_in(6 downto 5),
          25            => instr_in(2),
          24 downto 18  => "0000001",
          17 downto 15  => instr_in(9 downto 7),
          14 downto 13  => "00",
          12            => instr_in(13),
          11 downto 10  => instr_in(11 downto 10),
           9 downto  8  => instr_in(4 downto 3),
           7            => instr_in(12),
           6 downto  0  => c_opcode_branch
        );
      when others =>
        illegal_instr <= '1';
      end case;
    when c_opcode_c2 =>
      case instr_in(15 downto 13) is
      when "000" => -- C.SLLI
        instr_out <= (
          31 downto 25  => '0',
          24 downto 20  => instr_in(6 downto 2),
          19 downto 15  => instr_in(11 downto 7),
          14 downto 12  => "001",
          11 downto  7  => instr_in(11 downto 7),
           6 downto  0  => c_opcode_op_imm
        );
        illegal_instr <= instr_in(12);
      when "010" => -- C.LWSP
        instr_out <= (
          31 downto 28  => '0',
          27 downto 26  => instr_in(3 downto 2),
          25            => instr_in(12),
          24 downto 22  => instr_in(6 downto 4),
          21 downto 12  => "0000010010",
          11 downto  7  => instr_in(11 downto 7),
           6 downto  0  => c_opcode_load
        );
        illegal_instr <= nor instr_in(11 downto 7);
      when "100" =>
        if instr_in(12) = '0' then
          if nor instr_in(6 downto 2) then
            -- C.JR
            instr_out <= (
              31 downto 20  => '0',
              19 downto 15  => instr_in(11 downto 7),
              14 downto  7  => '0',
               6 downto  0  => c_opcode_jalr
            );
          else
            -- C.ADD
            instr_out <= (
              31 downto 25  => '0',
              24 downto 20  => instr_in(6 downto 2),
              19 downto 12  => "00000001",
              11 downto  7  => instr_in(11 downto 7),
               6 downto  0  => c_opcode_op
            );
          end if;
        else
          if nor instr_in(6 downto 2) then
            if nor instr_in(11 downto 7) then
              -- C.EBREAK
              instr_out <= x"0010_0073";
            else
              -- C.JALR
              instr_out <= (
                31 downto 20  => '0',
                19 downto 15  => instr_in(11 downto 7),
                14 downto  7  => "00000001",
                 6 downto  0  => c_opcode_jalr
              );
            end if;
          else
            -- C.ADD
            instr_out <= (
              31 downto 25  => '0',
              24 downto 20  => instr_in(6 downto 2),
              19 downto 15  => instr_in(11 downto 7),
              14 downto 12  => "000",
              11 downto  7  => instr_in(11 downto 7),
               6 downto  0  => c_opcode_op
            );
          end if;
        end if;
      when "110" => -- C.SWSP
        instr_out <= (
          31 downto 28  => "0000",
          27 downto 26  => instr_in(8 downto 7),
          25            => instr_in(12),
          24 downto 20  => instr_in(6 downto 2),
          19 downto 12  => "00010010",
          11 downto  9  => instr_in(11 downto 9),
           8 downto  7  => "00",
           6 downto  0  => c_opcode_store
        );
      when others =>
        illegal_instr <= '1';
      end case;
    when others =>
      -- Uncompressed
      instr_out <= instr_in;
    end case;
  end process;

end architecture;