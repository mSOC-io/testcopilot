import whois
import requests

def get_ip_info(ip_address):
    # Get WHOIS information (using whoisxmlapi or other library if needed)
    try:
        whois_info = whois.whois(ip_address)
        asn = whois_info.asn if hasattr(whois_info, 'asn') else "Not available"
        cidr = whois_info.cidr if hasattr(whois_info, 'cidr') else "Not available"
    except Exception as e:
        asn = "Lookup failed"
        cidr = "Lookup failed"

    # Get geolocation information
    try:
        geo_response = requests.get(f"https://ipinfo.io/{ip_address}/json")
        geo_info = geo_response.json()
        country = geo_info.get("country", "Unknown")
    except Exception:
        country = "Lookup failed"

    # Prepare the output
    ip_info = {
        "IP Address": ip_address,
        "AS Number": asn,
        "CIDR Block": cidr,
        "Country": country
    }
    return ip_info

if __name__ == "__main__":
    ip_address = input("Enter an IP address: ")
    info = get_ip_info(ip_address)
    for k, v in info.items():
        print(f"{k}: {v}")
