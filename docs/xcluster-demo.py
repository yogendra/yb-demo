#!/usr/bin/env python3

def yba_api():
  print("yba_api")

def get_provider_by_id():
  print("provider-id")

def get_universe():
  print("universe")

def setup_pitr():
  print("pitr")

def get_ca_certificate(cluster):
  print(f"get cert for {cluster}");

API_KEY=None
def get_api_key(login,password):
  if API_KEY ==  None:
    # Login
    # Get session info
    API_KEY="API_KEY"
  return API_KEY

def provider_id(name):
  print(f'uuid-of-universe-${name}')

def universe_uuid(name):
  print(f'uuid-of-provide-${name}')

def setup_transactional_xcluster():



def help():
  print("help")

if __name__ == "__main__":
    print("Hello, World!")
