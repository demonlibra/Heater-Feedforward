;--- Калибровка коррекции нагревателя HotEnd`а от скорости экструзии ---
;-----------------------------------------------------------------------


;============================== Параметры ==============================
;-----------------------------------------------------------------------

var k_start=0.000             ; Указать начальный коэффициент коррекции
var k_step=0.010              ; Указать изменение коэффициента за шаг
var steps_number=3            ; Указать количество тестов

var filament_diameter=1.75    ; Указать диаметр филамента, мм
var filament_length=60        ; Указать длину филамента для одного теста, мм
var extrusion_volume_speed=10 ; Указать объём экструзии, мм.куб/сек

var hotend=1                  ; Указать номер HotEnd`а
var temperature_hotend=230    ; Указать температуру HotEnd`а, C

var tool_number=0             ; Указать номер инструмента

var temperature_deviation=0.3 ; Указать допустимое отклонение температуры при определении стабилизации температуры, С
var time_stability=10         ; Указать время определения стабилизации температуры, сек

;-----------------------------------------------------------------------
;-----------------------------------------------------------------------
;=======================================================================
;=======================================================================


; --------------------------- Стартовый код ----------------------------

T{var.tool_number}                                                      ; Выбор инструмента
M83                                                                     ; Выбор относительных координат оси экструдера
M109 S{var.temperature_hotend}                                          ; Нагрев HotEnd`а с ожиданием достижения температуры

var check_counter=0
while var.check_counter <= var.time_stability                           ; Ожидание стабилизации температуры
   if {mod(heat.heaters[var.hotend].current-var.temperature_hotend) <= var.temperature_deviation}
      set var.check_counter=var.check_counter+1                         ; Счётчик стабильной температуры
   else
      set var.check_counter=0                                           ; Обнуление счётчика стабильной температуры
   G4 S1                                                                ; Пауза 1 секунду


; ---------------------------- Калибровка ------------------------------

var sectional_area=pi*var.filament_diameter*var.filament_diameter/4     ; Расчёт площади сечения прутка, мм.кв
var extrusion_speed=var.extrusion_volume_speed/var.sectional_area*60    ; Расчёт скорости подачи филамента, мм/мин

var k_counter=1
var max_temperature=var.temperature_hotend
var min_temperature=var.temperature_hotend

while var.k_counter <= var.steps_number
   M309 S{var.k_start+(var.k_counter-1)*var.k_step}                     ; Задание коэффициента коррекции нагревателя
   echo "Коэффициент коррекции нагревателя M309 S"^var.k_start+(var.k_counter-1)*var.k_step

   G1 E{var.filament_length} F{var.extrusion_speed}                     ; Подача филамента

   set var.max_temperature=var.temperature_hotend
   set var.min_temperature=var.temperature_hotend
   set var.check_counter=0

   while var.check_counter <= var.time_stability                        ; Ожидание стабилизации температуры
      if {heat.heaters[var.hotend].current > var.max_temperature}       ; Определение максимумальной температуры
         set var.max_temperature=heat.heaters[var.hotend].current

      if {heat.heaters[var.hotend].current < var.min_temperature}       ; Определение минимальной температуры
         set var.max_temperature=heat.heaters[var.hotend].current

      if {mod(heat.heaters[var.hotend].current-var.temperature_hotend) < var.temperature_deviation}
         set var.check_counter=var.check_counter+1                      ; Счётчик стабильной температуры
      else
         set var.check_counter=0                                        ; Обнуление счётчика стабильной температуры

      G4 S1                                                             ; Пауза 1 секунду

   echo "Максимальная температура "^var.max_temperature                 ; Вывод максимальной температуры в консоль
   echo "Минимальная температура "^var.min_temperature                  ; Вывод минимальной температуры в консоль

   set var.k_counter=var.k_counter+1                                    ; Увеличение счётчика шага коэффициента


; --------------------------- Завершающий код --------------------------   

M104 S0                                                                 ; Выключить нагреватель HotEnd`а
M140 S0                                                                 ; Выключить нагреватель стола
M107                                                                    ; Выключить вентилятор обдува модели
M18                                                                     ; Выключить питание моторов
M300 P1000                                                              ; Звуковой сигнал
