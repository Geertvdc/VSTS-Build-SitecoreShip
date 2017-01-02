Param(
     [string]$sitecoreUrl, 
     [string]$fileUrl
 )

Write-Host "create httpclient"
Add-Type -AssemblyName System.Net.Http
$httpClientHandler = New-Object System.Net.Http.HttpClientHandler
$httpClient = New-Object System.Net.Http.Httpclient $httpClientHandler
$packageFileStream = New-Object System.IO.FileStream @($fileUrl, [System.IO.FileMode]::Open)

Write-Host "file opened"
        
$contentDispositionHeaderValue = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue "form-data"
$contentDispositionHeaderValue.Name = "path"
$contentDispositionHeaderValue.FileName = (Split-Path $fileUrl -leaf)


$streamContent = New-Object System.Net.Http.StreamContent $packageFileStream
$streamContent.Headers.ContentDisposition = $contentDispositionHeaderValue
$streamContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue "application/octet-stream"
        
$content = New-Object System.Net.Http.MultipartFormDataContent
$content.Add($streamContent)

Write-Host "form content created"

try
{
    Write-Host "before postAsync"
    $response = $httpClient.PostAsync("$sitecoreUrl/services/package/install/fileupload", $content).Result
    Write-Host "After postAsync"

    if (!$response.IsSuccessStatusCode)
    {
        Write-Host "Not success"
        $responseBody = $response.Content.ReadAsStringAsync().Result
        $errorMessage = "Status code {0}. Reason {1}. Server reported the following message: {2}." -f $response.StatusCode, $response.ReasonPhrase, $responseBody

        Write-Host "$errorMessage"
        throw [System.Net.Http.HttpRequestException] $errorMessage
    }

    return $response.Content.ReadAsStringAsync().Result
}
finally
{
    if($null -ne $httpClient)
    {
        $httpClient.Dispose()
    }

    if($null -ne $response)
    {
        $response.Dispose()
    }
}