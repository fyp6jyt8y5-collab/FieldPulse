using System.Drawing;
using System.Drawing.Imaging;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Windows.Forms;

const int mousePort = 45454;
const int streamPort = 8080;
_ = Task.Run(() => RunMouseServer(mousePort));
await RunStreamServer(streamPort);

static async Task RunMouseServer(int port)
{
    using UdpClient udp = new(port);
    Console.WriteLine($"Mouse control listening on UDP {port}");
    while (true)
    {
        UdpReceiveResult result = await udp.ReceiveAsync();
        try
        {
            MousePacket? packet = JsonSerializer.Deserialize<MousePacket>(result.Buffer, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
            if (packet is null) continue;
            if (packet.Type.Equals("move", StringComparison.OrdinalIgnoreCase)) Mouse.Move((int)packet.Dx, (int)packet.Dy);
            if (packet.Type.Equals("click", StringComparison.OrdinalIgnoreCase)) Mouse.LeftClick();
        }
        catch (JsonException) { }
    }
}

static async Task RunStreamServer(int port)
{
    TcpListener listener = new(System.Net.IPAddress.Any, port);
    listener.Start();
    Console.WriteLine($"Screen stream ready at http://PC-IP:{port}/stream");
    while (true)
    {
        TcpClient client = await listener.AcceptTcpClientAsync();
        _ = Task.Run(async () => await HandleStreamClient(client));
    }
}

static async Task HandleStreamClient(TcpClient client)
{
    using (client)
    {
        NetworkStream stream = client.GetStream();
        byte[] requestBuffer = new byte[4096];
        int bytesRead = await stream.ReadAsync(requestBuffer);
        string request = System.Text.Encoding.ASCII.GetString(requestBuffer, 0, bytesRead);
        if (!request.StartsWith("GET /stream ", StringComparison.Ordinal))
        {
            await stream.WriteAsync("HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n"u8.ToArray());
            return;
        }
        await stream.WriteAsync("HTTP/1.1 200 OK\r\nCache-Control: no-cache\r\nConnection: close\r\nContent-Type: multipart/x-mixed-replace; boundary=frame\r\n\r\n"u8.ToArray());
        await StreamScreen(stream);
    }
}

static async Task StreamScreen(NetworkStream stream)
{
    try
    {
        while (true)
        {
            using Bitmap bitmap = new(Screen.PrimaryScreen?.Bounds.Width ?? 1280, Screen.PrimaryScreen?.Bounds.Height ?? 720);
            using (Graphics graphics = Graphics.FromImage(bitmap)) graphics.CopyFromScreen(0, 0, 0, 0, bitmap.Size);
            using MemoryStream image = new();
            bitmap.Save(image, ImageFormat.Jpeg);
            byte[] jpeg = image.ToArray();
            byte[] header = System.Text.Encoding.ASCII.GetBytes($"--frame\r\nContent-Type: image/jpeg\r\nContent-Length: {jpeg.Length}\r\n\r\n");
            await stream.WriteAsync(header);
            await stream.WriteAsync(jpeg);
            await stream.WriteAsync("\r\n"u8.ToArray());
            await stream.FlushAsync();
            await Task.Delay(100);
        }
    }
    catch { }
}

internal sealed record MousePacket(string Type, double Dx, double Dy);

internal static class Mouse
{
    [DllImport("user32.dll", SetLastError = true)] private static extern uint SendInput(uint count, INPUT[] inputs, int size);
    public static void Move(int dx, int dy) { if (dx == 0 && dy == 0) return; Send(new MOUSEINPUT { Dx = dx, Dy = dy, Flags = 0x0001 }); }
    public static void LeftClick() { Send(new MOUSEINPUT { Flags = 0x0002 }); Send(new MOUSEINPUT { Flags = 0x0004 }); }
    private static void Send(MOUSEINPUT mouse) { SendInput(1, [new INPUT { Type = 0, Data = new InputUnion { Mouse = mouse } }], Marshal.SizeOf<INPUT>()); }
    [StructLayout(LayoutKind.Sequential)] private struct INPUT { public uint Type; public InputUnion Data; }
    [StructLayout(LayoutKind.Explicit)] private struct InputUnion { [FieldOffset(0)] public MOUSEINPUT Mouse; }
    [StructLayout(LayoutKind.Sequential)] private struct MOUSEINPUT { public int Dx; public int Dy; public uint MouseData; public uint Flags; public uint Time; public nint ExtraInfo; }
}
