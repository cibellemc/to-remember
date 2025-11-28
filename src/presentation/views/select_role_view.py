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

        # --- AppBar (Header do Passo a Passo) ---
        self.appbar = ft.AppBar(
            title=ft.Column([
                ft.Text("Seleção de Perfil", color=TEXT_LIGHT, size=18, weight=ft.FontWeight.BOLD),
                ft.Text("Passo 1 de 3", color=TEXT_MUTED, size=12),
            ], spacing=0, alignment=ft.MainAxisAlignment.CENTER),
            center_title=True,
            leading=ft.IconButton(
                icon=ft.Icons.ARROW_BACK,
                on_click=self.go_back_to_login, # Volta pro Login (cancelar cadastro)
                icon_color=TEXT_LIGHT
            ),
            bgcolor=ft.Colors.WHITE,
            elevation=0
        )

        # --- Cards (Lógica Visual) ---
        self.patient_card = self.create_role_card(
            role_name="patient",
            title="Paciente",
            subtitle="A pessoa que vai treinar a memória",
            icon_control=ft.Icon(ft.Icons.ELDERLY, size=60, color=PRIMARY)
        )
        
        self.caregiver_card = self.create_role_card(
            role_name="caregiver",
            title="Cuidador",
            subtitle="Alguém que ajuda outra pessoa",
            icon_control=ft.Icon(ft.Icons.HEALTH_AND_SAFETY_OUTLINED, size=60, color=PRIMARY)
        )

        # Texto de Apoio
        header_text = ft.Text(
            value="Quem vai usar este aplicativo?",
            size=18,
            text_align=ft.TextAlign.CENTER,
            color=TEXT_MUTED, 
        )

        cards_row = ft.Row(
            [self.patient_card, self.caregiver_card],
            alignment=ft.MainAxisAlignment.CENTER,
            spacing=20,
        )

        main_content = ft.Container(
            content=ft.Column(
                [header_text, cards_row],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=30, 
            ),
            alignment=ft.alignment.center,
            expand=True,
        )

        # Botão Continuar
        self.continue_button = ActionButton( 
            text="Continuar",
            on_click=self.go_to_step_2
        )
        
        # Inicia desabilitado visualmente
        self.continue_button.content.disabled = True 
        self.continue_button.opacity = 0.5 

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
        # ... (Mantém a mesma lógica de criação visual do card) ...
        title_text = ft.Text(title, size=20, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT)
        subtitle_text = ft.Text(subtitle, size=14, color=TEXT_MUTED, text_align=ft.TextAlign.CENTER)
        
        card = ft.Container(
            content=ft.Column(
                [icon_control, title_text, subtitle_text],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=10,
            ),
            width=160, height=200, border_radius=12,
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
        
        # Reset visual
        for card in [self.patient_card, self.caregiver_card]:
            card.bgcolor = ft.Colors.WHITE
            card.border = ft.border.all(2, ft.Colors.GREY_300)
            card.icon_control.color = PRIMARY
            card.title_text.color = TEXT_LIGHT
            card.subtitle_text.color = TEXT_MUTED

        # Destaque selecionado
        selected = self.patient_card if role == "patient" else self.caregiver_card
        selected.bgcolor = PRIMARY 
        selected.border = ft.border.all(4, ft.Colors.WHITE)
        selected.icon_control.color = ft.Colors.WHITE
        selected.title_text.color = ft.Colors.WHITE
        selected.subtitle_text.color = ft.Colors.WHITE
            
        # Habilita botão
        self.continue_button.content.disabled = False
        self.continue_button.opacity = 1.0 
        self.continue_button.update() 
        self.update() 

    def go_to_step_2(self, e):
        if self.selected_role:
            # Vai para a RegisterView (Passo 2)
            self.page.go(f"/register/{self.selected_role}")

    def go_back_to_login(self, e):
        self.page.go("/login")