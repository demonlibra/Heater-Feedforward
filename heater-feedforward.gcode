;--- Калибровка коррекции нагревателя HotEnd`а от скорости экструзии ---
;-----------------------------------------------------------------------


;============================== Параметры ==============================
;-----------------------------------------------------------------------

var temperature_hotend=230    ; Указать температуру HotEnd`а, C

var k_start=0.000             ; Указать начальный коэффициент heater feedforward
var k_step=0.010              ; Указать изменение коэффициента за шаг
var steps_number=3            ; Указать количество тестов

var filament_length=60        ; Указать длину филамента для одного теста, мм
var filament_diameter=1.75    ; Указать диаметр филамента, мм
var extrusion_volume=10       ; Указать объём экструзии, мм.куб/сек

var pause=120                 ; Указать время достаточное для стабилизации температуры

var thermistor=1              ; Указать номер термистора

;-----------------------------------------------------------------------
;-----------------------------------------------------------------------
;=======================================================================
;=======================================================================


; --------------------------- Стартовый код ----------------------------

var extrusion_speed=var.extrusion_volume/(pi*var.filament_diameter*var.filament_diameter/4)

M83                                                                     ; Выбор относительных координат оси экструдера
M109 S{var.temperature_hotend}                                          ; Нагрев HotEnd`а с ожиданием достижения температуры

var check_counter=0
while var.check_counter > 30                                            ; Ожидание стабилизации температуры
   if {mod(sensors[var.thermistor].lastReadin-var.temperature_hotend) < 0.3}
      set var.check_counter=var.check_counter+1                         ; Счётчик стабильной температуры
   G4 S1                                                                ; Пауза 1 секунду

var time_counter=0
var counter=0
var max_temperature=var.temperature_hotend
var min_temperature=var.temperature_hotend

while var.counter < var.steps_number
   M309 {var.k_start+var.counter*var.k_step}
   echo "Коэффициент heater feedforward "^var.k_start+var.counter*var.k_step
   G1 E{var.filament_length} F{var.extrusion_speed}

   set var.time_counter=0
   set var.max_temperature=var.temperature_hotend
   set var.min_temperature=var.temperature_hotend
   set var.check_counter=0

   while var.check_counter > 30
      if {sensors[var.thermistor].lastReading > var.max_temperature}    ; Определение максимумальной температуры
         set var.max_temperature=sensors[1].lastReading

      if {sensors[var.thermistor].lastReading < var.min_temperature}    ; Определение минимальной температуры
         set var.max_temperature=sensors[1].lastReading

      if {mod(sensors[var.thermistor].lastReadin-var.temperature_hotend) < 0.3}
         set var.check_counter=var.check_counter+1                      ; Счётчик стабильной температуры

      G4 S1                                                             ; Пауза 1 секунду

   echo "Максимальная температура "^var.max_temperature                 ; Вывод максимальной температуры в консоль
   echo "Минимальная температура "^var.min_temperature                  ; Вывод минимальной температуры в консоль

   set var.counter=var.counter+1                                        ; Увеличение счётчика шага коэффициента


; --------------------------- Завершающий код --------------------------   

M104 S0                                                                 ; Выключить нагреватель HotEnd`а
M140 S0                                                                 ; Выключить нагреватель стола
M300 P1000                                                              ; Звуковой сигнал
M107                                                                    ; Выключить вентилятор обдува модели
M18                                                                     ; Выключить питание моторов
