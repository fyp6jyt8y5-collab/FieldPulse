using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Text.Json;

const int port = 45454;
using var udp = new UdpClient(port);
Console.WriteLine($"FieldPulse Head Mouse listening on UDP {port}");
Console.WriteLine("Press Ctrl+C to stop.");

while (true)
{
    UdpReceiveResult result = await udp.ReceiveAsync();
    try
    {
        MotionPacket? packet = JsonSerializer.Deserialize<MotionPacket>(result.Buffer);
        if (packet is null) continue;
        Mouse.Move((int)(packet.Y * packet.Sensitivity * 18), (int)(packet.X * packet.Sensitivity * 18));
    }
    catch (JsonException) { }
}

internal sealed record MotionPacket(double X, double Y, double Sensitivity);

internal static class Mouse
{
    [DllImport("user32.dll", SetLastError = true)]
    private static extern uint SendInput(uint numberOfInputs, INPUT[] inputs, int sizeOfInput);

    public static void Move(int dx, int dy)
    {
        if (dx == 0 && dy == 0) return;
        INPUT[] inputs = [new INPUT { Type = 0, Data = new InputUnion { Mouse = new MOUSEINPUT { Dx = dx, Dy = dy, Flags = 0x0001 } } }];
        _ = SendInput(1, inputs, Marshal.SizeOf<INPUT>());
    }

    [StructLayout(LayoutKind.Sequential)] private struct INPUT { public uint Type; public InputUnion Data; }
    [StructLayout(LayoutKind.Explicit)] private struct InputUnion { [FieldOffset(0)] public MOUSEINPUT Mouse; }
    [StructLayout(LayoutKind.Sequential)] private struct MOUSEINPUT { public int Dx; public int Dy; public uint MouseData; public uint Flags; public uint Time; public nint ExtraInfo; }
}
