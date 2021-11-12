#include <lvgl/lvgl.h>
#include <sdl_driver.h>

#define BUFSIZE SDL_HOR_RES * SDL_VER_RES / 10

void driver_init() {
  lv_init();
  sdl_init(); 
  
  // draw buffer
  //
  static lv_disp_draw_buf_t draw_buf;
  static lv_color_t buf1[BUFSIZE];
  static lv_color_t buf2[BUFSIZE];
  lv_disp_draw_buf_init(&draw_buf, buf1, buf2, BUFSIZE);

  // display driver
  //
  static lv_disp_drv_t disp_drv;
  lv_disp_drv_init(&disp_drv);
  disp_drv.draw_buf = &draw_buf;
  disp_drv.flush_cb = sdl_display_flush;
  disp_drv.hor_res = SDL_HOR_RES;
  disp_drv.ver_res = SDL_VER_RES;
  disp_drv.antialiasing = 1;
 
  lv_disp_t *disp = lv_disp_drv_register(&disp_drv);
  lv_theme_t *thm = lv_theme_default_init(disp, 
      lv_palette_main(LV_PALETTE_BLUE), 
      lv_palette_main(LV_PALETTE_RED), 
      LV_THEME_DEFAULT_DARK, 
      LV_FONT_DEFAULT);
  lv_disp_set_theme(disp, thm);
   
  lv_group_t * g = lv_group_create();
  lv_group_set_default(g);
  
  // mouse driver
  //
  static lv_indev_drv_t indev_drv_1;
  lv_indev_drv_init(&indev_drv_1); 
  indev_drv_1.type = LV_INDEV_TYPE_POINTER;
  indev_drv_1.read_cb = sdl_mouse_read;
  lv_indev_t *mouse_indev = lv_indev_drv_register(&indev_drv_1);
  
  static lv_indev_drv_t indev_drv_2;
  lv_indev_drv_init(&indev_drv_2); 
  indev_drv_2.type = LV_INDEV_TYPE_ENCODER;
  indev_drv_2.read_cb = sdl_mousewheel_read; 
  
  lv_indev_t * enc_indev = lv_indev_drv_register(&indev_drv_2);
  lv_indev_set_group(enc_indev, g); 
  
  // keyboard driver
  //
  static lv_indev_drv_t indev_drv_3;
  lv_indev_drv_init(&indev_drv_3); 
  indev_drv_3.type = LV_INDEV_TYPE_KEYPAD;
  indev_drv_3.read_cb = sdl_keyboard_read;
  lv_indev_t *kb_indev = lv_indev_drv_register(&indev_drv_2);
  lv_indev_set_group(kb_indev, g);
}
