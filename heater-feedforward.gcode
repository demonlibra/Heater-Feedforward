;-----------------------------------------------------------------------
;--- Калибровка коррекции нагревателя HotEnd`а от скорости экструзии ---
;-----------------------------------------------------------------------

; https://uni3d.store/viewtopic.php?t=1030
; https://docs.duet3d.com/en/User_manual/Reference/Gcodes#m309-set-or-report-heater-feedforward

;============================== Параметры ==============================
;-----------------------------------------------------------------------

var k_start=0.000             ; Указать начальный коэффициент коррекции
var k_step=0.005              ; Указать изменение коэффициента за шаг
var steps=5                   ; Указать количество тестов

var filament_diameter=1.75    ; Указать диаметр филамента, мм
var filament_length=60        ; Указать длину филамента для одного теста, мм
var extrusion_flowrate=10     ; Указать требуемую объёмную скорость экструзии, мм.куб/сек

var temperature_hotend=230    ; Указать температуру HotEnd`а, C
var temperature_deviation=0.5 ; Указать допустимое отклонение температуры при определении стабилизации температуры, С
var time_stability=30         ; Указать время определения стабилизации температуры, сек

var tool=0                    ; Указать номер инструмента
var hotend=1                  ; Указать номер HotEnd`а

;-----------------------------------------------------------------------
;-----------------------------------------------------------------------
;=======================================================================
;=======================================================================


; --------------------------- Стартовый код ----------------------------

T{var.tool}                                                             ; Выбор инструмента
M83                                                                     ; Выбор относительных координат оси экструдера

echo "Нагрев HotEnd`а до температуры "^var.temperature_hotend
M109 S{var.temperature_hotend}                                          ; Нагрев HotEnd`а с ожиданием достижения температуры

echo "Ожидание стабилизации температуры"
var check_counter=0
while var.check_counter < var.time_stability                            ; Ожидание стабилизации температуры
   if {mod(heat.heaters[var.hotend].current-var.temperature_hotend) <= var.temperature_deviation}
      set var.check_counter=var.check_counter+1                         ; Счётчик стабильной температуры
   else
      set var.check_counter=0                                           ; Обнуление счётчика стабильной температуры
   G4 S1                                                                ; Пауза 1 секунду


; ---------------------------- Калибровка ------------------------------

var sectional_area=pi*var.filament_diameter*var.filament_diameter/4     ; Расчёт площади сечения прутка, мм.кв
var extrusion_speed=var.extrusion_flowrate/var.sectional_area*60        ; Расчёт скорости подачи филамента, мм/мин

var k_counter=1
var max_temperature=var.temperature_hotend
var min_temperature=var.temperature_hotend

while var.k_counter <= var.steps
   M309 S{var.k_start+(var.k_counter-1)*var.k_step}                     ; Задание коэффициента коррекции нагревателя
   echo "Коэффициент коррекции нагревателя M309 S"^var.k_start+(var.k_counter-1)*var.k_step

   G1 E{var.filament_length} F{var.extrusion_speed}                     ; Подача филамента
   echo "Ожидание стабилизации температуры"
   
   set var.max_temperature=var.temperature_hotend                       ; Сброс значения максимальной температуры
   set var.min_temperature=var.temperature_hotend                       ; Сброс значения минимальной температуры
   set var.check_counter=0                                              ; Сброс счётчика проверки стабилизации температуры

   while var.check_counter <= var.time_stability                        ; Ожидание стабилизации температуры
      if {heat.heaters[var.hotend].current > var.max_temperature}       ; Определение максимумальной температуры
         set var.max_temperature=heat.heaters[var.hotend].current

      if {heat.heaters[var.hotend].current < var.min_temperature}       ; Определение минимальной температуры
         set var.min_temperature=heat.heaters[var.hotend].current

      if {mod(heat.heaters[var.hotend].current-var.temperature_hotend) < var.temperature_deviation}
         set var.check_counter=var.check_counter+1                      ; Счётчик стабильной температуры
      else
         set var.check_counter=0                                        ; Обнуление счётчика стабильной температуры

      G4 S1                                                             ; Пауза 1 секунду

   echo "Максимальная температура "^var.max_temperature^"Отклонение +"^var.max_temperature-var.temperature_hotend  ; Вывод максимальной температуры в консоль
   echo "Минимальная температура "^var.min_temperature^"Отклонение -"^var.temperature_hotend-var.min_temperature   ; Вывод минимальной температуры в консоль
   echo "Разброс температуры "^var.max_temperature-var.min_temperature

   set var.k_counter=var.k_counter+1                                    ; Увеличение счётчика шага коэффициента


; --------------------------- Завершающий код --------------------------   

M104 S0                                                                 ; Выключить нагреватель HotEnd`а
M140 S0                                                                 ; Выключить нагреватель стола
M107                                                                    ; Выключить вентилятор обдува модели
M18                                                                     ; Выключить питание моторов
M300 P1000                                                              ; Звуковой сигнал
