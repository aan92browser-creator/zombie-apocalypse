param(
    [string]$Command = 'list',
    [string]$Server = '127.0.0.1',
    [int]$Port = 25575,
    [string]$Password = 'za'
)
$ErrorActionPreference = 'Stop'
$client = New-Object System.Net.Sockets.TcpClient
$client.Connect($Server, $Port)
$stream = $client.GetStream()
$stream.ReadTimeout = 5000

function Send-Packet([int]$id, [int]$type, [string]$body) {
    $payload = [Text.Encoding]::UTF8.GetBytes($body)
    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)
    $bw.Write([int]($payload.Length + 10))
    $bw.Write([int]$id)
    $bw.Write([int]$type)
    $bw.Write($payload)
    $bw.Write([byte]0)
    $bw.Write([byte]0)
    $bytes = $ms.ToArray()
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush()
}

function Read-Full([byte[]]$buf, [int]$count) {
    $read = 0
    while ($read -lt $count) {
        $n = $stream.Read($buf, $read, $count - $read)
        if ($n -le 0) { throw 'connection closed' }
        $read += $n
    }
}

function Read-Packet {
    $hdr = New-Object byte[] 4
    Read-Full $hdr 4
    $len = [BitConverter]::ToInt32($hdr, 0)
    $buf = New-Object byte[] $len
    Read-Full $buf $len
    $id = [BitConverter]::ToInt32($buf, 0)
    $type = [BitConverter]::ToInt32($buf, 4)
    $body = [Text.Encoding]::UTF8.GetString($buf, 8, $len - 10)
    [pscustomobject]@{ id = $id; type = $type; body = $body }
}

Send-Packet 1 3 $Password
$auth = Read-Packet
if ($auth.id -eq -1) { throw 'rcon auth failed' }
Send-Packet 2 2 $Command
$resp = Read-Packet
$resp.body
$client.Close()
