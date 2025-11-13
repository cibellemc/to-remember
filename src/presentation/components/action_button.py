import flet as ft
from common.colors import PRIMARY, TEXT_WHITE 

class ActionButton(ft.Container):
    def __init__(self, text: str, on_click: callable):
        super().__init__()
        
        self.padding = ft.padding.only(bottom=40, left=40, right=40)
        self.alignment = ft.alignment.center
        
        self.content = ft.ElevatedButton(
            text=text,
            on_click=on_click,
            style=ft.ButtonStyle(
                padding=ft.padding.symmetric(vertical=24, horizontal=32),
                text_style=ft.TextStyle(
                    size=18, 
                    weight=ft.FontWeight.BOLD
                ),
                shape=ft.RoundedRectangleBorder(radius=10),
                bgcolor=PRIMARY,
                color=TEXT_WHITE,
                elevation=4,
            ),
            expand=True,
        )