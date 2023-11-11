pub const help =
\\Usage: hersha [OPTION]... [FILE]...
\\Print or check SHA1 (160-bit) checksums.
\\
\\With no FILE, or when FILE is -, read standard input.
\\  -b, --binary          read in binary mode
\\  -c, --check           read checksums from the FILEs and check them
\\      --tag             create a BSD-style checksum
\\  -t, --text            read in text mode (default)
\\  -z, --zero            end each output line with NUL, not newline,
\\                          and disable file name escaping
\\
\\The following five options are useful only when verifying checksums:
\\      --ignore-missing  don't fail or report status for missing files
\\      --quiet           don't print OK for each successfully verified file
\\      --status          don't output anything, status code shows success
\\      --strict          exit non-zero for improperly formatted checksum lines
\\  -w, --warn            warn about improperly formatted checksum lines
\\
\\      --help        display this help and exit
\\      --version     output version information and exit
\\
\\The sums are computed as described in FIPS-180-1.
\\When checking, the input should be a former output of this program.
\\The default mode is to print a line with: checksum, a space,
\\a character indicating input mode ('*' for binary, ' ' for text
\\or where binary is insignificant), and name for each FILE.
\\
\\Note: There is no difference between binary mode and text mode on GNU systems.
;
