import pandas as pd
import sys
import os

# Check if there are enough arguments
if len(sys.argv) < 3:
    print("Usage: python excelMerge.py <output_file> <input_file1> [<input_file2> ...]")
    print("For .ods file support, make sure you have odfpy installed: pip install odfpy")
    sys.exit(1)

# Get output and input file paths from command line arguments
output_file = sys.argv[1]
input_files = sys.argv[2:]

dfs = []
for p in input_files:
    try:
        file_ext = os.path.splitext(p)[1].lower()
        if file_ext == '.ods':
            try:
                df = pd.read_excel(p, engine="odf")
            except ImportError:
                print("Error: 'odfpy' is not installed. Please install it to read .ods files: pip install odfpy")
                sys.exit(1)
        else:
            df = pd.read_excel(p)
        dfs.append(df)
    except Exception as e:
        print(f"Error reading file {p}: {e}")
        dfs.append(pd.DataFrame({"error":[str(e)], "file":[p]}))

# Concatenate all dataframes
if dfs:
    merged = pd.concat(dfs, ignore_index=True)

    # Save the merged dataframe to the output file
    try:
        file_ext = os.path.splitext(output_file)[1].lower()
        if file_ext == '.csv':
            merged.to_csv(output_file, index=False)
        elif file_ext in ['.xlsx', '.xls', '.ods']:
            # Use odf engine for .ods output as well
            if file_ext == '.ods':
                merged.to_excel(output_file, index=False, engine="odf")
            else:
                merged.to_excel(output_file, index=False)
        else:
            print(f"Unsupported output file format: {file_ext}")
            print("Saving as excel file by default (.xlsx)")
            merged.to_excel(f"{os.path.splitext(output_file)[0]}.xlsx", index=False)

        print(f"Merged file saved to {output_file}")
    except Exception as e:
        print(f"Error saving file {output_file}: {e}")
else:
    print("No dataframes to merge.")
