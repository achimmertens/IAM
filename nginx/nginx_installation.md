Ich möchte einen fertigen nginx Webserver als podman Container herunterladen. Die Webseite soll lokal erstellt und von dem Container gemountet werden.

# Webseite erstellen
Dazu erstelle ich erst einmal eine rudimentäre Webseite auf meinem PC:
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tGVYZoxcoSAMn6gWsEsvj64pBEp85LZAPeKzbp2yUCSYya2w3vzf1Ls6mFrGnCqNFZL.png)

# Nginx Container starten
Nun wird das Image von Nginx heruntergeladen:
> podman pull nginx:latest
> 
![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/23tkmusg6qMG6PLHxrj6eS5mAiKZ3uP6q4bycGNxEuQUB5ZCnMaDNhGvcX2GWwsGQ4TpW.png)

Den Podman mit einem Mountpoint starten. (Mit volume gab bei mir Schwierigkeiten, ich konnte nachträglich keine Datei hochladen)
> podman run -d --name nginx-webserver --mount type=bind,source=/d/IAM/nginx,target=/usr/share/nginx/html,readonly -p 8080:80 nginx:latest

![grafik.png](https://files.peakd.com/file/peakd-hive/achimmertens/243qTpRnaTucvesgrfxqq1pzqANytXjEqPzR3r2rHVSFFj93e1qCiMHoxa8JspwNgCfGp.png)

Der Container wird gestoppt mit
> podman stop nginx-webserver

...und gestartet mit:
> podman start nginx-webserver

