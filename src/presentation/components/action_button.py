import flet as ft


class ActionButton(ft.ElevatedButton):
    
    def __init__(self, text: str, on_click, expand=True, visible=True):
        
        super().__init__(
            text=text,
            on_click=on_click,
            expand=expand,
            visible=visible,
            
            style=ft.ButtonStyle(
                padding=ft.padding.symmetric(vertical=16, horizontal=32),
                text_style=ft.TextStyle(
                    size=18, 
                    weight=ft.FontWeight.BOLD
                ),
                shape=ft.RoundedRectangleBorder(radius=10) 
            ),
        )