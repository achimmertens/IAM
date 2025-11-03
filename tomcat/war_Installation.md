<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Ich möchte eine ganz simple \*.war Datei von Hand erstellen, also mit Java Befehlen. Wie geht das?

Um eine ganz einfache `.war`-Datei *von Hand* zu erstellen, benötigst du im Wesentlichen nur das Java Development Kit (JDK) und das Tool `jar` (im JDK enthalten). Beispielhaft kannst du damit eine sehr simple Webanwendung (z. B. mit einer einzigen HTML-Datei oder Servlet) direkt packen.

### Schritt-für-Schritt: Minimale `.war`-Datei erstellen

#### 1. Verzeichnisstruktur anlegen

Lege ein neues Arbeitsverzeichnis an, z. B. `simplewar`:

```bash
mkdir -p simplewar/WEB-INF
```


#### 2. Beispiel-Startseite (index.html) erstellen

Lege im Ordner `simplewar/` eine einfache `index.html` an:

```html
<!-- simplewar/index.html -->
<!DOCTYPE html>
<html>
<head><title>Welcome</title></head>
<body>
  <h1>Meine minimale WAR</h1>
</body>
</html>
```


#### 3. Web.xml als leere/kleine Deployment-Deskriptor-Datei anlegen

Lege im Unterordner `WEB-INF` eine ganz einfache `web.xml` an (für Tomcat ab Version 3.0 kannst du das sogar leer lassen):

```xml
<!-- simplewar/WEB-INF/web.xml -->
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee
                             http://xmlns.jcp.org/xml/ns/javaee/web-app_3_0.xsd"
         version="3.0">
</web-app>
```


#### 4. WAR-Datei mit dem `jar`-Befehl erstellen

Wechsle in das Arbeitsverzeichnis `simplewar` und führe aus:

```bash
cd simplewar
jar cvf ../simple.war *
```

Das erstellt die Datei `simple.war` *eine Ebene höher*. (Alternativ kannst du als Ziel einen anderen Pfad angeben.)

#### 5. WAR im Tomcat bereitstellen

Kopiere die Datei wie gewohnt in dein Tomcat-Container/Webapps-Verzeichnis. Tomcat erkennt sie und stellt sie bereit, z. B.:

```bash
podman cp ../simple.war Tomcat_Sailpoint:/usr/local/tomcat/webapps/simple.war
```

Die Seite ist dann auf `http://localhost:8080/simple/index.html` erreichbar.

***

### Hinweise:

- Für eine Anwendung mit Servlets musst du im Ordner `WEB-INF/classes` die kompilierten `.class`-Dateien ablegen und entsprechende `web.xml`-Einträge machen.
- Für Dyn-Inhalte reicht index.html statt index.jsp – JSPs liegen einfach als Datei im WAR.

**Kurz gesagt:**
Nur das Verzeichnis `WEB-INF` und optional andere statische Dateien (HTML, JSP, etc) anlegen, dann per `jar` packen. Keine zusätzliche Software nötig, nur das im JDK enthaltene `jar`-Tool.

Wenn du ein konkretes Servlet als Beispiel möchtest, ergänze einfach das Klassenverzeichnis und die web.xml passend!

