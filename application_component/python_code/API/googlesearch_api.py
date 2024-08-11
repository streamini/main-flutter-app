from googlesearch import search

# Define the search query
query = "chelsea"

# Perform the search and retrieve the first URL
try:
    first_url = next(search(query, num_results=1))
    print(first_url)
except StopIteration:
    print("No results found")
except Exception as e:
    print(f"An error occurred: {e}")