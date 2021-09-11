; Tähtitieteen tutkimusprojekti I projektityö
; Tähtikartta
; Samppa Alatalo - 2503288
; Samppa.Alatalo@student.oulu.fi
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Aliohjelma syötteen pyytämiselle ja kelpaavan muodon
; tarkistamiselle. Aliohjelmaluonne mahdollistaa tarkistuksen
; toteutuksen, jossa annetun syote-muuttujan aliohjelman ulkopuolella
; määritetty luonne määrittää sen kelpaamisen syötteelle.
; Käytetty virheentarkistus perustuu IDL:n dokumentaation esimerkkiin:
; https://www.l3harrisgeospatial.com/docs/on_ioerror.html
PRO lue_syote,syote,syoteviesti=sv,virheviesti=vv,vertaus=vrt,vertailuvirhe=vrtv
  valid = 0                     ;oikeellisuuden ilmaisin
  viesti = ''                   ;syötettä pyydettäessä näytettävä viesti
  virhe = ''                    ;virheen sattuessa näytettävä viesti
  verrattava = ''               ;regex, johon syötettä verrataan
  vrtvirhe = ''                 ;viesti, joka näytetään, jos vertailu täsmää
  if keyword_set(sv) then viesti = string(sv)
  if keyword_set(vv) then virhe = string(vv)
  if keyword_set(vrt) then verrattava = string(vrt)
  if keyword_set(vrtv) then vrtvirhe = string(vrtv)
  
  while valid EQ 0 do begin
     on_ioerror,bad_input
     if keyword_set(sv) then read,syote,prompt=viesti $
     else read,syote
     if keyword_set(vrt) then begin
        syote_str = string(syote)
        if NOT syote_str.Matches(verrattava) then begin
           if keyword_set(vrtv) then print,vrtvirhe
           continue
        endif
     endif
     valid = 1
     bad_input: if ~ valid then begin
        if keyword_set(vv) then print,virhe $
        else continue
     endif
  endwhile
end

; Funktio tarkistaa onko annettu arvo ylärajan (yla) ja alarajan (ala)
; välissä ja palauttaa 1, jos näin on. Avainsanat salli_ala ja
; salli_yla sallivat vastaaville raja-arvoille osuvat arvot.
FUNCTION tarkista_raja,arvo,ala,yla,virheviesti,salli_ala=alaeq,salli_yla=ylaeq
  ; Suorita tarkistukset ja palauta tosi, jos jokin niistä toteutuu.
  if (arvo GT ala) AND (arvo LT yla) then return,1
  ; Jos jompi kumpi avainsana on annettu, tarkista rajatapaukset.
  if keyword_set(alaeq) AND (arvo EQ ala) then return,1
  if keyword_set(ylaeq) AND (arvo EQ yla) then return,1

  ; Jos mikään yllä ei toteudu, palauta epätosi ja virheviestit.
  print,virheviesti
  print,ala,yla,format='("Arvon on oltava väliltä ", F0.1, " - ", F0.1)'
  if keyword_set(alaeq) then print,'Alarajan arvo on sallittu.'
  if keyword_set(ylaeq) then print,'Ylärajan arvo on sallittu.'
  return,0
end

; Simppeli funktio, joka kysyy vahvistusta jatkamiselle.
; Palauttaa totuusarvon vastauksen perusteella. Oletuksena 1.
FUNCTION vahvista,kysymys
  vahvistus = ''
  read,vahvistus,prompt=kysymys
  if vahvistus.Contains('y',/FOLD_CASE) $
     OR vahvistus.Contains('1',/FOLD_CASE) $
     OR vahvistus.Contains('k',/FOLD_CASE) $
     OR vahvistus EQ '' then return,1 $
  else return,0
end

;;;;;; Pääohjelma alkaa

;;; Esittely
print,''
print,'Tervetuloa hienoon tähtikarttaan!'
print,'Tekijä: Samppa Alatalo'

;;; Datan lukeminen
print,'Valmistellaan dataa...'
n = file_lines('kirkkaat_tahdet.dat') - 3 ;kolme otsikkoriviä
ra = fltarr(n) & dec = ra & vmag = ra
openr,1,'kirkkaat_tahdet.dat'
otsikkoroskaa = ''
for i=0,2 do readf,1,otsikkoroskaa ;eroon tekstiriveistä
for i=0,n-1 do begin
   readf,1,rai,deci,vmagi
   ra[i] = rai
   dec[i] = deci
   vmag[i] = vmagi
endfor
close,1
print,'Data OK'
print,''

;;; Maantieteellisen sijainnin hankkiminen
while 1 do begin
   
   lat = 0.
   lon = 0.

   print,'Anna haluamasi maantieteellinen sijainti asteina desimaalilukuna.'
   print,'Käytä vastakkaisille suunnille negatiivista merkkiä.'

   ; Virheviestit
   numvirhe = 'Arvo on annettava numerona.'
   rajavirhe = 'Arvo on rajojen ulkopuolella!'

   ; Leveysasteen syöttö
   valid = 0                    ;oikeellisuuden ilmaisin
   while valid EQ 0 do begin
      lue_syote,lat,syoteviesti='Anna leveysaste pohjoista leveyttä: ',virheviesti=numvirhe
      lat = lat mod 90.
      if NOT tarkista_raja(lat,-90.,90.,rajavirhe,/salli_ala,/salli_yla) then continue
      valid = 1
   endwhile

   ; Pituusasteen syöttö
   valid = 0
   while valid EQ 0 do begin
      lue_syote,lon,syoteviesti='Anna pituusaste itäistä pituutta: ',virheviesti=numvirhe
      lon = lon mod 180.
      if NOT tarkista_raja(lon,-180.,180.,rajavirhe,/salli_ala,/salli_yla) then continue
      valid = 1
   endwhile

   ; Käyttömukavuutta lisäävä tuloste ja jatkamisen vahvistus
   print,''
   print,lat,lon,format='("Valittu sijainti: ",F0.2,"P ",F0.2,"I")'
   if vahvista('Jatketaanko ([y]/n)? ') then break else print,'Otetaan alusta...'
   print,''
   
endwhile
print,''

;;; Halutun ajan hankkiminen
while 1 do begin
   
   aika = ''
   aika_j = double(0)
   ; Syötteen kelpaamisen tarkistukseen käytettävä regular expression -merkkijono
   vrt = '^ *$|^ *[Jj][0-9]+\.?([0-9]+)? *$|^ *(([0-2]?[1-9])|([123][01]))\.((0?[1-9])|(1[0-2]))\.-?'
   vrt += '((0*[1-9])|([1-9][0-9]+))( (([0-1]?[0-9])|(2[0-3]))[:.]([0-5]?[0-9])([:.]([0-5]?[0-9]))?)? *$'
   
   print,'Anna haluamasi ajankohta joko juliaanisena tai gregoriaanisena muodossa'
   print,'"JXXXX(.X)" tai "DD.MM.YYYY( HH:MM:SS)" vastaavasti.'
   print,'Suluilla merkityt osat ovat vapaaehtoisia.'
   print,'Kellonaika tulkitaan universaalina aikana (UT).'
   print,'Jätä tyhjäksi käyttääksesi nykyhetkeä.'

   ; Luetaan käyttäjän syöte aikamuuttujaan ja tarkistetaan
   lue_syote,aika,syoteviesti='Anna ajankohta: ',virheviesti='Syöte ei kelpaa!',$
             vertaus=vrt,vertailuvirhe='Ajankohdan muoto ei kelpaa!'
   aika = aika.Trim() ;mahd. ylimääräiset välit pois

   if aika EQ '' then begin
      print,'Nykyhetki valittu.'
      aika_j = systime(/JULIAN,/UTC)
   endif else if NOT aika.StartsWith('J',/FOLD_CASE) then begin
      greg = fix(aika.Split('[ .:]') ) ;päiväyksen osien erottelu
      ; Jos vapaaehtoisia ei ole täytetty, täydennetään
      if n_elements(greg) LT 6 then greg = [greg,intarr(6-n_elements(greg) ) ]
      ; Muunnetaan juliaaniseksi
      aika_j = julday(greg(1),greg(0),greg(2),greg(3),greg(4),greg(5) )
   endif else aika_j = double(aika.Remove(0,0) ) ;muutoin vain poistetaan 'J'
   
   ; Käyttömukavuutta
   print,''
   print,aika_j,format='("Valittu ajankohta: J",F0.1)'
   if vahvista('Jatketaanko ([y]/n)? ') then break else print,'Otetaan alusta...'
   print,''
   
endwhile
print,''

;;; Tähtien sijaintien laskeminen
; Muunnetaan ekvatoriaaliset koordinaatit horisonttimuotoon,
; samalla sijainnit päivitetään valittuun aikaan.
az = fltarr(n_elements(ra) ) & alt = fltarr(n_elements(dec) )
eq2hor,ra,dec,aika_j,alt,az,lat=lat,lon=lon

; Erotellaan datasetistä valitun sijainnin taivas.
inds = where(az GE 0. AND az LE 360. AND alt GE 0. AND alt LE 90.)
az_vali = [] & alt_vali = [] & vmag_vali = []
az_vali = az[inds]
alt_vali = alt[inds]
vmag_vali = vmag[inds]
print,'Tähtien sijainnit laskettu.'

;;; Magnitudien ryhmittely
; Käytetyn datasetin magnitudiväli on -1.46 - 7.96.
; Toteutus perustuu IDL-harjoitustyöhön.
vmag_i = list()
for i=0,8 do begin
   ; Alkuun erotetaan tapaus <-1
   if i EQ 0 then vmag_i.add,[where(vmag_vali LT float(i-1),/NULL)] $
   else begin
      ; Lisätään magnitudit yhden magnitudin välein
      vmag_i.add,[where(vmag_vali GE float(i-2) $
                        AND vmag_vali LT float(i-1),/NULL)]
   endelse
endfor
; Lisätään vielä tapaus >7
vmag_i.add,[where(vmag_vali GE 7.,/NULL)]

;;; Kartan piirtäminen
; Valmistellaan oleellisia parametrejä
vmag_koko = vmag_i.count() - 1  ;silmukkamuuttujan yläraja
pos = [0.1,0.1,0.75,0.9]        ;arvo plot-komennon position-avainsanalle
syms = 1.5                      ;symsize-avainsanan alkuarvo
color = indgen(vmag_koko+2)     ;color-avainsanan arvotaulukko
remove,1,color                  ;poistetaan taustaväri (1)
; Selitteen nimilista ja alkusijainti
selite = ['<-1','-1<0','0<1','1<2','2<3','3<4','4<5','5<6','6<7','>7']
selite_x = pos[2] + 0.05        ;selitteen kuvakkeen x-koordinaatin alkuarvo
selite_y = pos[3] - 0.05        ;selitteen y-koordinaatin alkuarvo
nimi_x = selite_x + 0.03        ;selitteen tekstin x-koordinaatin alkuarvo

; Valmistellaan PostScript-piirtäminen
psopen,'./tahtikartta.ps',/COLOR
nwin

; Atsimuutti täytyy /POLAR-muotoa varten ensin muuntaa radiaaneiksi ja
; kulmaan, jonka nollakohta on lännessä.
; Korkeus täytyy myös muuttaa zeniitin mukaiseksi.
theta = (az_vali + 90.) * !dtor
sade = 90. - alt_vali

; Kartan alustus
plot,/POLAR,/YNOZERO,/NODATA,[0,1],[0,1],$
     xr=[-90.,90.],yr=[-90.,90.],xticki=5.,yticki=5.,$
     xticklen=1.,yticklen=1.,xg=2,yg=2,$
     position=pos,xs=4,ys=4,psym=2,symsize=syms,color=color[0]

; Lisätään selkeyttäviä akseliviivoja.
; Ensin paloitellaan ympyrä 16 osaan ja luodaan säteen suuntaiset
; akselit.
kulmat = (2 * !pi / 16.) * findgen(17) ;kulmat radiaaneina
r_i = [0.,90.]                         ;säteet
; Valmistellaan kulmien merkkitekstit.
; Piirtäminen alkaa lännestä (270 astetta).
kulmaots = string([270.:337.5:22.5],format='(F0.1)')
kulmaots = [kulmaots, string([0.:247.5:22.5],format='(F0.1)')]
foreach kulmanimi, kulmaots, i do begin
   if kulmanimi.endswith('.0') then kulmaots[i] = kulmaots[i].remove(-2)
endforeach
kulmaots = kulmaots + tex2idl('$^{o}$') ;lisätään astemerkki
; Määritetään vielä piirtoteknisiä parametrejä
kohd_x = [2.5:-2.5:-0.625]      ;siirrot x-suunnassa
kohd_x = [kohd_x, [-1.875:1.875:0.625]]
kohd_y = [0.:2.5:0.625]         ;siirrot y-suunnassa
kohd_y = [kohd_y, [1.875:-2.5:-0.625], [-1.875:-0.625:0.625]]
kierto = [270.:337.5:22.5]      ;tekstin kiertokulmat
kierto = [kierto, [0.:247.5:22.5]]
; Määritetään diagonaalikulmat lisämerkintöjä varten
diagon = where( (kulmat EQ !pi / 4.) OR (kulmat EQ 3 * !pi / 4.) $
                OR (kulmat EQ 5 * !pi / 4.) OR (kulmat EQ 7 * !pi / 4.) )
diag_kierto = intarr(n_elements(kulmat) )
; Lisämerkintöjä kierretään 90 astetta suhteessa päätyihin
diag_kierto[diagon] = [90, -90, -90, 90]

; Piirretään akselit ja kulmien tekstit
foreach kulma, kulmat, i do begin
   merkki_x = r_i * cos(kulma)
   merkki_y = r_i * sin(kulma)
   plots,merkki_x,merkki_y,thick=0.5 ;piirtää akselit
   ; Kulmamerkintöjen piirtäminen
   if i NE n_elements(kulmat)-1 then begin
      xyouts,merkki_x[1]+kohd_x[i],merkki_y[1]+kohd_y[i],kulmaots[i],$
             align=0.5,ori=kierto[i],chars=0.7
      ; Diagonaaleille tulee lisämerkintä akselin puoliväliin
      if diagon.HasValue(i) then begin
         xyouts,merkki_x[1]/2.+kohd_x[i],merkki_y[1]/2.+kohd_y[i],kulmaots[i],$
                align=0.5,ori=kierto[i]+diag_kierto[i],chars=0.7
      endif
   endif
endforeach

; Lisätään vielä sädettä merkitsevät väliympyrät
pisteet = (2 * !pi / 99.) * findgen(100) ;lajitelma kulmia ympyröille
sateet = [5:90:5]                        ;ympyröiden säteet
ax_numerot = string([85:5:-5],format='(I0)') ;sädemerkinnät
; Ympyröiden tyyli vuorottelee kiinteän ja katkoviivojen välillä
viivatyyli = intarr(n_elements(ax_numerot) )
viivatyyli[0:*:2] = 2

; Piirretään sädeympyrät ja -merkinnät
foreach r_j, sateet, j do begin
   rinki_x = r_j * cos(pisteet)
   rinki_y = r_j * sin(pisteet)
   ; Uloin ympyrä tulee paksumpana ja ilman merkintöjä
   if r_j EQ 90 then plots,rinki_x,rinki_y,thick=2 $
   else begin
      plots,rinki_x,rinki_y,lin=viivatyyli[j],thick=0.5 ;piirtää sädeympyrät
      ; Lisätään sädemerkinnät
      xyouts,r_j,-4.,ax_numerot[j],align=0.5,chars=0.7  ;positiivinen x-akseli
      xyouts,-r_j,-4.,ax_numerot[j],align=0.5,chars=0.7 ;negatiivinen x-akseli
      xyouts,-1.,r_j-1.5,ax_numerot[j],align=1.,chars=0.7 ;positiivinen y-akseli
      ; Negatiivisen y-akselin kohdalla jätetään origon alueen merkki pois
      if j NE 0 then xyouts,-1.,-r_j-1.5,ax_numerot[j],align=1.,chars=0.7
   endelse
endforeach

; Tähtien piirtäminen kartalle
xyouts,selite_x-0.0075,selite_y+1/20.,'Magnitudit',/NORMAL ;selitteen otsikko
for i=0,vmag_koko do begin
   if vmag_i[i] NE !NULL then begin
      oplot,/POLAR,sade[vmag_i[i] ],theta[vmag_i[i] ],$
            psym=2,symsize=syms,color=color[i]
   endif
   ; Lisätään selite
   plots,selite_x,selite_y-i/20.,psym=2,symsize=syms,color=color[i],/NORMAL
   xyouts,nimi_x,selite_y-0.0075-i/20.,selite[i],/NORMAL
   syms -= 0.1
endfor

; Piirretään otsikko erikseen.
; Perustuu IDL Coyoten ratkaisuun:
; http://www.idlcoyote.com/graphics_tips/noroom.html
otsikko = string(lat,tex2idl('$^{o}$'),lon,tex2idl('$^{o}$'),aika_j,$
                 format='("Taivas ",F0.2,A0," P ",F0.2,A0," I, J",F0.1)')
ots_x = (!x.window[1] - !x.window[0]) / 2. + !x.window[0]
ots_y = 0.94
xyouts,ots_x,ots_y,otsikko,/normal,align=0.5,chars=1.25
print,'Kartan piirtäminen valmis.'

;;; PostScriptin muuntaminen ja lopetus
psclose
spawn,'ps2pdf tahtikartta.ps'
print,'tahtikartta.pdf luotu.'
if vahvista('Haluatko avata tiedoston nyt ([y]/n)? ') then begin
   print,'Avataan tahtikartta.pdf...'
   spawn,'xpdf tahtikartta.pdf &'
endif

print,''
print,'Kiitos tähtikarttaohjelman käytöstä!'
print,''

end
