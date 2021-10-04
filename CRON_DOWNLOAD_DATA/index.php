<?php

set_time_limit(300);

const PATH = 'https://opensky-network.org/api/states/all';
const COUNTRY = 'Poland';
const AIRLINE = 'LOT';

$header_opts = array(
    'http'=>array(
        'header'=>	"Accept-language: pl,en-us;q=0.7,en;q=0.3\r\n" .
            "User-Agent: Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Mobile Safari/537.36\r\n"
    )
);
$context = stream_context_create($header_opts);

$json = file_get_contents(PATH, false, $context);
$jsonDec = json_decode($json);
$jsonTab = $jsonDec->states;

$tabCSVFin = [];
$j = 0;
for($i=1;$i<count($jsonTab);$i++)
{
    if ($jsonTab[$i][2] === COUNTRY and substr($jsonTab[$i][1], 0, 3) === AIRLINE)
    {
        $country = $jsonTab[$i][2];
        $flightNumber =  $jsonTab[$i][1];

        /*$htmlCodeDownload = file_get_contents("https://flightaware.com/live/flight/" . $flightNumber);

        $ch = curl_init("https://flightaware.com/live/flight/" . $flightNumber);
        $fp = fopen("https://flightaware.com/live/flight/" . $flightNumber, "w");
        curl_setopt($ch, CURLOPT_FILE, $fp);
        curl_setopt($ch, CURLOPT_HEADER, 0);
        $htmlCodeDownload = curl_exec($ch);
        curl_close($ch);
        fclose($fp);*/

        $config['useragent'] = 'Mozilla/5.0 (Windows NT 6.2; WOW64; rv:17.0) Gecko/20100101 Firefox/17.0';


        $url = "https://uk.flightaware.com/live/flight/" . $flightNumber;

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_AUTOREFERER, TRUE);
        curl_setopt($ch, CURLOPT_HEADER, 0);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, TRUE);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 3);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, FALSE);
        curl_setopt($ch, CURLOPT_USERAGENT, $config['useragent']);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Accept-Language: en']);
        $response = curl_exec($ch);
        curl_close($ch);

        $htmlCodeDownload = $response;

        $htmlCode = mb_convert_encoding($htmlCodeDownload, "UTF-8",
            mb_detect_encoding($htmlCodeDownload, "UTF-8, ISO-8859-2", true));

        $cutPage = str_replace("Int'l", '', str_replace('"', '', substr($htmlCode,
            strpos($htmlCode, 'trackpollBootstrap ') + 21,
            strpos($htmlCode, 'trackpollGlobals'))));

        $cutStart = substr($cutPage, strpos($cutPage, 'origin'), strpos($cutPage, 'destination'));
        $cutEnd = substr($cutPage, strpos($cutPage, 'destination'), strpos($cutPage, 'aircraftType'));
        $typePlane = substr($cutPage, strpos($cutPage, 'aircraftType'), strpos($cutPage, 'takeoffTimes'));

        $startValues = explode(':', $cutStart);
        $startValuesCity = explode(',', $startValues[8]);
        $startValuesAirport = explode(',',  $startValues[7]);

        $endValues = explode(':', $cutEnd);
        $endValuesCity = explode(',', $endValues[8]);
        $endValuesAirport = explode(',', $endValues[7]);

        $planeValues = explode(':', $typePlane);
        $planeFriendlyValue = explode(',', $planeValues[2]);

        $cityStart = $startValuesCity[0];
        $airportStart = $startValuesAirport[0];
        $cityEnd = $endValuesCity[0];
        $airportEnd = $endValuesAirport[0];
        $planeModel = $planeFriendlyValue[0];

        $tabFin = [
            date('Y-m-d H:i:s'),
            trim($country),
            trim($flightNumber),
            trim($cityStart),
            trim($airportStart),
            trim($cityEnd),
            trim($airportEnd),
            trim($planeModel)
        ];

        $lineCsv = implode(';', $tabFin);

        $tabCSVFin[$j] = $lineCsv;

        echo $lineCsv;
        echo "<br/>";

        $j++;
    }
}

function createCSV(string $mode, string $path, array $tabCSVFinFunc) : bool
{
    $checkExistFile = TRUE;

    $titleCol = "datetime;country_plane;flight_number;city_start;airport_start;city_end;airport_end;model_plane";

    if (!file_exists($path)){
        $checkExistFile = FALSE;
    }

    $fp = fopen($path, $mode);

    if ($checkExistFile === FALSE){
        fputs($fp, $titleCol."\n");
    }

    for($i = 0; $i<count($tabCSVFinFunc); $i++) {
        fwrite($fp, $tabCSVFinFunc[$i]."\n");
    }

    fclose($fp);

    return true;
}

$actualDate = date("Y-m-d");

createCSV("a", "FILES_CSV/all_data_flight.csv", $tabCSVFin);
createCSV("w", "FILES_CSV/all_data_flight_$actualDate.csv", $tabCSVFin);

echo "Dane zostały pobrane!";