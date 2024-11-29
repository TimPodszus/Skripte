import pandas as pd
import tkinter as tk
from tkinter import filedialog

root = tk.Tk()
root.withdraw()


file_path = filedialog.askopenfilename()


# Load the CSV file
df = pd.read_csv(file_path)

# Filter out rows where 'Latest Delivery Location' is 'Quarantine'
df_filtered = df[df['Latest delivery location'] != 'Quarantine']

# Count occurrences of each email address
email_counts = df_filtered['Sender address'].value_counts()

# Filter email addresses that occur more than once
duplicate_emails = email_counts[email_counts > 1]

# Ask for user input for the output file path
output_file_path = filedialog.asksaveasfilename(title="Save results as...", defaultextension=".csv", initialfile="results.csv")

# Export duplicate email addresses to a CSV file
duplicate_emails.to_csv(output_file_path, header=True)

# Print confirmation
print("Duplicate email addresses have been exported to:", output_file_path)