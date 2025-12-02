# Rootless Docker & Docker Swarm - Übersicht

Diese Datei ist eine **Übersicht** über beide Themen. Für detaillierte Informationen siehe die separaten Guides:

## 📚 Separate Guides

### 1. [ROOTLESS-DOCKER-GUIDE.md](./ROOTLESS-DOCKER-GUIDE.md)
**Kompletter Guide zu Rootless Docker:**
- Was ist Rootless Docker?
- Installation und Setup
- Wie funktioniert es (User Namespaces, RootlessKit)
- Reverse Proxy Konfiguration (Traefik)
- Ports < 1024 Setup
- Docker Socket Anpassungen
- Praktische Beispiele
- Troubleshooting

### 2. [DOCKER-SWARM-GUIDE.md](./DOCKER-SWARM-GUIDE.md)
**Kompletter Guide zu Docker Swarm:**
- Was ist Docker Swarm?
- Architektur und Konzepte
- Setup und Konfiguration
- Migration: docker-compose → docker-stack
- Routing Mesh
- Shared Storage
- Management Commands
- Praktische Beispiele

### 3. [SWARM-MIGRATION-STEPS.md](./SWARM-MIGRATION-STEPS.md)
**Praktische Schritt-für-Schritt Anleitung:**
- Firewall Konfiguration
- Swarm initialisieren
- Services migrieren
- Troubleshooting
- Checkliste

---

## 🎯 Schnell-Entscheidung

### Nur Rootless Docker?
→ Siehe [ROOTLESS-DOCKER-GUIDE.md](./ROOTLESS-DOCKER-GUIDE.md)

### Nur Docker Swarm?
→ Siehe [DOCKER-SWARM-GUIDE.md](./DOCKER-SWARM-GUIDE.md)  
→ Siehe [SWARM-MIGRATION-STEPS.md](./SWARM-MIGRATION-STEPS.md) für praktische Schritte

### Beides kombinieren?
⚠️ **Warnung:** Rootless Docker + Swarm ist möglich, aber komplex und hat Einschränkungen.

**Empfehlung:**
- Für **Homelab**: Erst Swarm, dann Rootless (oder umgekehrt)
- Für **Produktion**: Normales Docker (mit Root) + Swarm ist einfacher
- **Alternative**: Podman (rootless by default) + Podman Swarm

---

## 🔗 Kombination: Rootless Docker + Swarm

### Probleme bei der Kombination

1. **Ports < 1024**: Brauchen CAP_NET_BIND_SERVICE oder höhere Ports
2. **Overlay Networks**: Können Probleme mit User Namespaces haben
3. **Docker Socket**: Muss für alle Nodes zugänglich sein
4. **Komplexität**: Deutlich mehr Setup-Aufwand

### Wenn du es trotzdem versuchen willst

1. **Rootless Docker auf allen Nodes installieren**
   - Siehe [ROOTLESS-DOCKER-GUIDE.md](./ROOTLESS-DOCKER-GUIDE.md)

2. **Swarm initialisieren**
   - Siehe [DOCKER-SWARM-GUIDE.md](./DOCKER-SWARM-GUIDE.md)

3. **Ports konfigurieren**
   - Nutze höhere Ports (8080/8443) oder CAP_NET_BIND_SERVICE
   - Router/NAT entsprechend anpassen

4. **Docker Socket anpassen**
   - In docker-stack.yml: `$XDG_RUNTIME_DIR/docker.sock` verwenden
   - Auf allen Nodes gleich konfigurieren

5. **Testen, testen, testen!**
   - In VM/Test-Environment zuerst
   - Schrittweise migrieren

---

## 📋 Quick Reference

Siehe [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) für:
- Wichtige Commands
- Migration-Cheatsheet
- Troubleshooting-Quick-Fixes

---

## 🚀 Empfohlener Weg

### Für Homelab (einfach):
1. **Docker Swarm** zuerst (siehe [DOCKER-SWARM-GUIDE.md](./DOCKER-SWARM-GUIDE.md))
2. **Rootless Docker** später (optional, siehe [ROOTLESS-DOCKER-GUIDE.md](./ROOTLESS-DOCKER-GUIDE.md))

### Für maximale Sicherheit:
1. **Rootless Docker** zuerst (siehe [ROOTLESS-DOCKER-GUIDE.md](./ROOTLESS-DOCKER-GUIDE.md))
2. **Swarm** später (optional, siehe [DOCKER-SWARM-GUIDE.md](./DOCKER-SWARM-GUIDE.md))

### Für Produktion:
- **Normales Docker + Swarm** (einfacher, bewährt)
- Oder: **Podman + Podman Swarm** (rootless by default)

---

**Viel Erfolg! 🎉**
