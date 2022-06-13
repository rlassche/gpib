# Dotnet on RPI

https://docs.microsoft.com/en-us/dotnet/iot/deployment

https://www.petecodes.co.uk/install-and-use-microsoft-dot-net-5-with-the-raspberry-pi/

Additional:

 dotnet tool install dotnet-ef -g


TODO:

1. Methode "keyboardDriver"
Bij prologix -> monitor commando's: 
a. ++addr
Geef adres door aan Read methode.

Bij Read data, het bron-adress tonen.
Later, doorsturen naar een websocket server.


2. Angular: webpage met:
a. Selectie gpib.conf
b. Text vak om commando in te voeren
c. Textblok waar de gelezen data in gezet wordt. 
Ontvangst via websockets.

3. Backend starten via windows service.
a. De Read method inbouwen in Server versie.
