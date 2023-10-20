from django.shortcuts import render
from rest_framework.decorators import api_view, renderer_classes
from rest_framework.renderers import JSONRenderer
from rest_framework.response import Response

from web3 import Web3, exceptions
from requests.exceptions import ConnectionError


infura_url = "https://mainnet.infura.io/v3/f3c095656381439aa1acb1722d9c62f2"
w3 = Web3(Web3.HTTPProvider(infura_url))


@api_view(("GET",))
@renderer_classes((JSONRenderer,))
def index(request):
    return Response(None, status=200)


# Web3 HTTPProvider has retries built in; no need to account for retries here.
@api_view(("GET",))
@renderer_classes((JSONRenderer,))
def balance(request, address):
    try:
        wei_balance = w3.eth.get_balance(address)
    # Capture inavlid address exceptions
    except exceptions.InvalidAddress as e:
        return Response({"error": str(e)}, status=400)
    # Capture issues with connecting to backend
    except ConnectionError as e:
        return Response({"error": "web3 backend unavailable"}, status=500)
    # get_balance method returns in wei, we need to convert to ether.
    ether_balance = w3.from_wei(wei_balance, "ether")
    return Response({"balances": ether_balance}, status=200)
