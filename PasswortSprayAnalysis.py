import csv
from collections import defaultdict

def analyze_csv(file_path):
    ip_count = {}
    usernames = set()
    user_ips = defaultdict(set)

    with open(file_path, mode='r') as file:
        csv_reader = csv.DictReader(file)
        for row in csv_reader:
            # Count client IPs
            ip = row.get("clientIp")
            if ip:
                if ip in ip_count:
                    ip_count[ip] += 1
                else:
                    ip_count[ip] = 1

            # Collect distinct usernames and their IPs
            user = row.get("user")
            if user:
                usernames.add(user)
                user_ips[user].add(ip)

    return ip_count, usernames, user_ips

def export_results(ip_count, usernames, user_ips, output_file):
    with open(output_file, mode='w') as file:
        file.write("Client IP Counts:\n")
        for ip, count in ip_count.items():
            file.write(f"{ip}: {count}\n")

        file.write("\nUsernames and their IPs:\n")
        for user, ips in user_ips.items():
            file.write(f"{user}: {', '.join(ips)}\n")

# Example usage
csv_file_path = 'C:/users/Podszus/Downloads/query_data(7).csv'  # Replace with the path to your CSV file
output_txt_file = 'C:/Users/podszus/Desktop/output.txt'

ip_count, usernames, user_ips = analyze_csv(csv_file_path)
export_results(ip_count, usernames, user_ips, output_txt_file)

print(f"Results have been exported to {output_txt_file}.")