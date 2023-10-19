from setuptools import setup

setup(
    name="blockchain_explorer",
    install_requires=[
        "Django==4.2.6",
        "djangorestframework==3.14.0",
        "web3==6.11.0",
        "tzdata==2023.3",
    ],
    packages=[
        "blockchain_explorer",
        "address",
        "address.migrations",
    ],
)
