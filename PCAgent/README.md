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

3. Autorise `HeadMouseAgent.exe` sur le réseau privé dans le pare-feu Windows.
4. Trouve l'adresse IP du PC avec `ipconfig`.
5. Dans FieldPulse > Head Mouse, saisis cette adresse et le port `45454`.
6. Active `Head tracking`.

L'iPhone et le PC doivent être sur le même Wi-Fi. Le serveur écoute uniquement le port UDP local ; ne redirige pas ce port vers Internet. Utilise un réseau privé de confiance.

Si la console affiche `FieldPulse Head Mouse listening on UDP 45454`, l'agent est prêt. Garde cette fenêtre ouverte pendant l'utilisation.
