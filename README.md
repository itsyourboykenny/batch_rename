# batch_rename
Command line shell utility to quickly rename a bunch of files. Supports sequential mode and also supports regex.
## Usage
`batchRename.sh [options] [file1 file2 file3 ...]`  
- `(-s | --seq) number`
  - Rename using numerical sequence. By default it will be appended
- `(-r | --regex) pattern`
  - Captures values from the files and uses its values to rename
  - Must use capture groups with (). Each corresponding groups are assigned to tags chronologically. ie: (group1)(group2)(group3) -> %1 %2 %3 respectively
- `(-f | --format) format`
  - Format of each files will use for renaming.
  - Requires at least 1 tag. ie: %1
  - Example: renamed_file_%1.txt
- `(-a | --append)`
  - Appends the sequence or values to the end of the file name
- `(-p | --prepend)`
  - Prepends the sequence or values to the beginning of the file
- `(--dry-run)`
  - Preview your changes. Nothing will be modified
- `(-d | --padding) number`
  - How may zeros to pad the sequence with. If omittited it will be generated
- `(-i | --ignore-extension)`
  - Extensions will be ignored"
## Example
`batchRename.sh --seq 1 --dry-run file1.txt file2.txt file3.txt`  
   file1 -> file11.txt  
   file2 -> file22.txt  
   file3 -> file33.txt  
  
`batchRename.sh --regex '([a-z]+)([0-9]+)' --format 'Renamed_%1_%2.png' --dry-run file1.txt file2.txt file3.txt`  
   file1.txt -> Renamed_file_1.png  
   file2.txt -> Renamed_file_2.png  
   file3.txt -> Renamed_file_3.png  
