function test_cb(event)
  print("button pressed")
end


local btn = lv.btn_create(lv.scr_act())
lv.obj_add_event_cb(btn, test_cb, 1, nil)

local txt = lv.label_create(btn)
lv.label_set_text(txt, "hello")
lv.obj_center(btn)
