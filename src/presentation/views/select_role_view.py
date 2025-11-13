import flet as ft
from common.colors import BACKGROUND_LIGHT, PRIMARY, TEXT_LIGHT, TEXT_MUTED
from presentation.components.action_button import ActionButton

class SelectRoleView(ft.View):
    def __init__(self, page: ft.Page):
        super().__init__(
            route="/select-role",
            bgcolor=BACKGROUND_LIGHT, 
            padding=ft.padding.all(20)
        )
        self.page = page
        self.selected_role = None 

        self.patient_card = self.create_role_card(
            role_name="patient",
            title="Paciente",
            subtitle="A pessoa que vai treinar a memória",
            icon_control=ft.Icon(
                ft.Icons.ELDERLY, 
                size=60, 
                color=PRIMARY 
            )
        )
        
        self.caregiver_card = self.create_role_card(
            role_name="caregiver",
            title="Cuidador",
            subtitle="Alguém que ajuda outra pessoa",
            icon_control=ft.Icon(
                ft.Icons.HEALTH_AND_SAFETY_OUTLINED, 
                size=60, 
                color=PRIMARY
            )
        )

        header_block = ft.Column(
            [
                ft.Text(
                    value="Selecione o seu perfil",
                    size=24,
                    weight=ft.FontWeight.BOLD,
                    text_align=ft.TextAlign.CENTER,
                    color=TEXT_LIGHT, 
                ),
                ft.Text(
                    value="Quem vai usar este aplicativo?",
                    size=16,
                    text_align=ft.TextAlign.CENTER,
                    color=TEXT_MUTED, 
                ),
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            spacing=5
        )

        cards_row = ft.Row(
            [
                self.patient_card,
                self.caregiver_card,
            ],
            alignment=ft.MainAxisAlignment.CENTER,
            spacing=20,
        )

        main_content = ft.Container(
            content=ft.Column(
                [
                    header_block,
                    cards_row,
                ],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=30, 
            ),
            alignment=ft.alignment.center,
            expand=True,
        )


        self.continue_button = ActionButton( 
            text="Continuar",
            on_click=self.go_to_login
        )
        
        self.continue_button.visible = False

        self.controls = [
            ft.Column(
                [
                    main_content,
                    self.continue_button 
                ],
                expand=True,
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                alignment=ft.MainAxisAlignment.CENTER,
            )
        ]

    def create_role_card(self, role_name: str, title: str, subtitle: str, icon_control: ft.Icon):
        
        # Cria os controles de texto
        title_text = ft.Text(
            title, 
            size=20, 
            weight=ft.FontWeight.BOLD, 
            color=TEXT_LIGHT 
        )
        
        subtitle_text = ft.Text(
            subtitle, 
            size=14, 
            color=TEXT_MUTED, 
            text_align=ft.TextAlign.CENTER
        )
        
        # Cria o card (Container)
        card = ft.Container(
            content=ft.Column(
                [
                    icon_control,
                    title_text,
                    subtitle_text
                ],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=10,
            ),
            width=160,  
            height=200, 
            border_radius=12,
            
            bgcolor=ft.Colors.WHITE, 
            border=ft.border.all(2, ft.Colors.GREY_300), 
            on_click=lambda e: self.select_role(role_name),
            data=role_name,
            padding=ft.padding.all(15),
        )
        
        card.icon_control = icon_control
        card.title_text = title_text
        card.subtitle_text = subtitle_text
        
        return card

    def select_role(self, role: str):
        self.selected_role = role
        
        self.patient_card.bgcolor = ft.Colors.WHITE
        self.patient_card.border = ft.border.all(2, ft.Colors.GREY_300)
        self.patient_card.icon_control.color = PRIMARY
        self.patient_card.title_text.color = TEXT_LIGHT
        self.patient_card.subtitle_text.color = TEXT_MUTED
        
        self.caregiver_card.bgcolor = ft.Colors.WHITE
        self.caregiver_card.border = ft.border.all(2, ft.Colors.GREY_300)
        self.caregiver_card.icon_control.color = PRIMARY
        self.caregiver_card.title_text.color = TEXT_LIGHT
        self.caregiver_card.subtitle_text.color = TEXT_MUTED

        selected_card = None
        if role == "patient":
            selected_card = self.patient_card
        else:
            selected_card = self.caregiver_card
            
        selected_card.bgcolor = PRIMARY 
        selected_card.border = ft.border.all(4, ft.Colors.WHITE)
        
        selected_card.icon_control.color = ft.Colors.WHITE
        selected_card.title_text.color = ft.Colors.WHITE
        selected_card.subtitle_text.color = ft.Colors.WHITE
            

        self.continue_button.visible = True
        self.update() 

    def go_to_login(self, e):
        if self.selected_role:
            self.page.go(f"/login/{self.selected_role}")