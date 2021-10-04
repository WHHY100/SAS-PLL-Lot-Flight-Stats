# SAS PLL LOT Flight Stats

* [Dane](#Dane)
* [Uruchomienie kodu](#Uruchomienie_projektu)
* [Prezentacja wyników](#Wizualizacja)
* [Wykorzystana technologia](#Technologia)

## Dane
Dane wykorzystane do projektu pobierane są z zewnętrznego API OpenSky (https://opensky-network.org). Aplikacja w wersji darmowej udostępnia podstawowe informacje o
wszystkich samolotach na świecie będących w danej chwili w powietrzu. Po stronie skryptu napisanego w PHP jest pobieranie pliku json, następnie filtrowanie wszystkich 
samolotów linii lotniczej PLL LOT, a finalnie dopisanie informacji o samolotach w powietrzu do pliku CSV. CRON odpytuje API codziennie w południe.
Dane na temat maszyn w powietrzu są zapisane zgodnie ze stanem faktycznym na godzinę 12:00 każdego dnia.

Dodatkowo w skrypcie SASowym wykorzystywane są dane z serwisu distance.to (https://www.distance.to/). Dzięki webscrapingowi jesteśmy w stanie określić odległości pomiędzy 
miastem początkowym i końcowym dla większości zarchiwizowanych lotów.

## Uruchomienie projektu

By uruchomić kod w swoim SAS Studio należy sklonować repozytorium i nie zmieniać struktury plików. Po modyfikacji ścieżek w skrypcie wszystko powinno zadziałać bez problemu. 
Natomiast w przypadku chęci uruchomienia skryptu pobierającego dane należy umieścić kod na swoim serwerze, a następnie ustawić CRONa tak by pobierał dane w zadanych przez 
nas interwałach czasowych.

## Wizualizacja

Dane przedstawione na wykresach pochodzą z przedziału czasowego od 23.09.2021 do 04.10.2021. Poniższy wykres prezentuje ilość lotów dla których zabraliśmy informacje 
w rozbiciu na poszczególne dni pracy CRONa.

![liczba lotow per dzien](https://github.com/WHHY100/SAS-PLL-Lot-Flight-Stats/blob/main/img/STATS_FLIGHTS_PER_DAY.jpg?raw=true)

Najwięcej maszyn PLL LOTu w powietrzu (33 sztuki) znajdowało się w dniu 30 września 2021 roku. Najmniej (zaledwie 18 sztuk) przypadło na dzień 3 października 2021 roku. 
Śmiało możemy stwierdzić, że każdego dnia w południe przeciętnie ponad 20 samolotów LOTu znajduje się w powietrzu.

![liczba lotow per samolot](https://github.com/WHHY100/SAS-PLL-Lot-Flight-Stats/blob/main/img/STATS_FLIGHTS_PER_PLANE.jpg?raw=true)

Wykres powyżej prezentuje ile razy dana maszyna została zaobserwowana w oknie czasowym badania. Zostały zliczone wszystkie loty zarchiwizowane w danym dniu. 
Możemy zauważyć, że samolotem najczęściej wykonującym loty, codziennie w godzinach południowych, jest brazylijski EMBRAER ERJ 190. Jest to samolot średniego zasięgu, może 
pomieścić na pokładzie około 100 osób (w zależności od konfiguracji). Drugim na liście popularności samolotem PLL LOT jest maszyna tej samej marki: EMBRAER 175, także
średniego zasięgu, mieszcząca na pokładzie około 80 osób. Pierwszy samolot popularnego amerykańskiego producenta znajduje się dopiero na 4 miejscu (BOEING 737 MAX). 
Jego debiut naznaczyły katastrofy spowodowane błędem w oprogramowaniu. W zestawieniu występuje także samolot turbośmigłowy de Havilland dash 8, 
którego zasięg dobiega zaledwie do 2500 km. Zestawienie zamyka EMBRAER ERJ 175, który wykonywał zaledwie 1 lot w badanym oknie czasowym. Być może powinien on się zawierać w 
grupie samolotów EMBRAERa 175, czyli drugiej najpopularniejszej maszyny, jednakże z powodu innego oznaczenia modelu został zakwalifikowany do odmiennej grupy.

![liczba lotow per samolot](https://github.com/WHHY100/SAS-PLL-Lot-Flight-Stats/blob/main/img/MEAN_DISTANCE_PER_PLANE.jpg?raw=true)

Powyższy wykres prezentuje średnie odległości jaki pokonuje dany model samolotu. W przypadku dwóch pierwszych Boeingów 787 (8 i 9 Dreamliner) uzyskujemy znacznie większe 
odległości niż przy pozostałych typach maszyn. Spowodowane jest to wykonywaniem lotów międzykontynentalnych przez te samoloty. Natomiast zadziwiać może zaskakująco niewielki 
dystans pokonywany przez Boeinga 737 Max i Boeinga 737-800. Krótkie trasy nie wykorzystują w pełni możliwości tych maszyn, gdyż każda z nich w specyfikacji udostępnionej 
przez producenta posiada kilka razy większy deklarowany dystans (w obu przypadkach koło 6 tysięcy kilometrów). Stawkę zamyka de Havilland dash 8, którego średni pokonywany 
dystans w barwach linii lotniczej PLL Lot wynosi niecałe 500km na przelot.

![liczba lotow per samolot](https://github.com/WHHY100/SAS-PLL-Lot-Flight-Stats/blob/main/img/POPULAR_DESTINATION_FLIGHTS.jpg?raw=true)

Powyższa tabela przedstawia najpopularniejsze miejsca docelowe wszystkich występujących w zestawieniu modeli samolotów, przy czym należy zauważyć, że jeżeli dwa kierunki przy 
danym typie samolotu były równie popularne, to każdy z nich jest wyszczególniony w tabeli. W badanym okresie czasowym Boeing 737 MAX najczęściej (po 2 razy) wykonywał loty 
do Madrytu i Barcelony. Boeing 737-800 aż 4-krotnie leciał do Lwowa, Dreamliner i 787-8 pokonywały trasy międzykontynentalne, natomiast de Havilland dash 8 latał z Warszawy 
do Gdańska. Warunkiem występowania samolotu w tej tabeli było rozpoczęcie danego lotu w Warszawie, ponieważ to lotnisko Chopina jest głównym portem dla lini lotniczej PLL LOT.

## Technologia

PHP 7.1

Oprogramowanie: *SAS Studio* ® w SAS® OnDemand

Wersja: *9.4_M6*
