Hier habe ich beschrieben, wie man den LDAP Server installiert:
https://peakd.com/hive-121566/@achimmertens/installation-eines-ldap-servers-via-podman-image

In diesem Dokument schreibe ich weitere Erfahrungen, sowie man den Server wartet.

# Podman starten
der LDAP-Server wurde ja als Container erstellt. Man findet ihn mit: 
> podman ps -a

Man kann den Container starten:
> podman start ldap-server
 bzw., wenn ich seine Logs dabei sehen möchte:

> podman start -a ldap_server

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tGVYZoxcoSAMn6gWsEsvj64pBEp85LZAPeKzbp2yUCSYya2w3vzf1Ls6mFrGnCqNFZL.png)