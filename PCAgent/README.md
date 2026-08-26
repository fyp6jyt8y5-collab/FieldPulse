# FieldPulse Head Mouse Agent

Agent Windows qui reçoit les mouvements de tête de l'iPhone en UDP et déplace la souris avec `SendInput`.

## Installation

1. Installe le SDK .NET 8 sur Windows depuis https://dotnet.microsoft.com/download/dotnet/8.0.
2. Dans ce dossier, double-clique `Start-HeadMouse.bat`, ou utilise PowerShell :

```powershell
dotnet run
```

Pour créer un exécutable autonome :

```powershell
dotnet publish -c Release
```

3. Autorise les ports du serveur dans le pare-feu Windows :

```powershell
New-NetFirewallRule -DisplayName "FieldPulse Remote Screen" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow -Profile Private
New-NetFirewallRule -DisplayName "FieldPulse Mouse" -Direction Inbound -Protocol UDP -LocalPort 45454 -Action Allow -Profile Private
```
4. Trouve l'adresse IP du PC avec `ipconfig`.
5. Dans FieldPulse > Remote Screen, saisis cette adresse et appuie sur `Connect`.
6. Touche l'écran du PC pour déplacer la souris ; relâche après un glissement pour faire un clic gauche.

L'iPhone et le PC doivent être sur le même Wi-Fi. Le serveur écoute uniquement le port UDP local ; ne redirige pas ce port vers Internet. Utilise un réseau privé de confiance.

Si la console affiche `Mouse control listening on UDP 45454` et `Screen stream ready`, l'agent est prêt. Garde cette fenêtre ouverte pendant l'utilisation.
