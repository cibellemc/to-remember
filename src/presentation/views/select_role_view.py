import flet as ft
# from presentation.components.action_button import ActionButton

class SelectRoleView(ft.View):
    def __init__(self, page: ft.Page):
        super().__init__(route="/select-role")
        self.page = page
        self.selected_role = None 

        self.continue_button = ft.Container(
            content=ft.ElevatedButton(
                text="Continuar",
                on_click=self.go_to_login,
                
                style=ft.ButtonStyle(
                    padding=ft.padding.symmetric(vertical=24, horizontal=32),
                    text_style=ft.TextStyle(
                        size=18, 
                        weight=ft.FontWeight.BOLD
                    ),
                    shape=ft.RoundedRectangleBorder(radius=10) 
                ),
                expand=True,
            ),
            padding=ft.padding.only(bottom=40, left=40, right=40), 
            alignment=ft.alignment.center,
        )
        
        # CARD 1: Paciente
        self.patient_card = self.create_role_card(
            role_name="patient",
            text="Paciente",
            icon_or_image=ft.Icon(ft.Icons.ELDERLY_WOMAN, size=80) 
        )
        
        # CARD 2: Cuidador
        self.caregiver_card = self.create_role_card(
            role_name="caregiver",
            text="Cuidador",
            icon_or_image=ft.Icon(ft.Icons.MEDICAL_SERVICES_OUTLINED, size=80)
        )

        # Container do "meio" (sem mudanças)
        main_content = ft.Container(
            content=ft.Column(
                [
                    ft.Text(
                        value="Selecione o seu perfil para começar",
                        size=18,
                        text_align=ft.TextAlign.CENTER,
                    ),
                    ft.Row(
                        [
                            self.patient_card,
                            self.caregiver_card,
                        ],
                        alignment=ft.MainAxisAlignment.CENTER,
                        spacing=20,
                    ),
                ],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=30,
            ),
            alignment=ft.alignment.center,
            expand=True,
        )

        self.controls = [
            ft.Column(
                [
                    main_content,
                    self.continue_button # Adiciona o componente
                ],
                expand=True
            )
        ]

    def create_role_card(self, role_name: str, text: str, icon_or_image: ft.Control):
        return ft.Container(
            content=ft.Column(
                [
                    icon_or_image,
                    ft.Text(text, size=18, weight=ft.FontWeight.BOLD)
                ],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=15,
            ),
            width=150,
            height=150,
            border_radius=12,
            bgcolor=ft.Colors.ON_SURFACE_VARIANT,
            on_click=lambda e: self.select_role(role_name),
            data=role_name,
            padding=10,
        )

    # select_role (sem mudanças)
    def select_role(self, role: str):
        self.selected_role = role
        
        self.patient_card.bgcolor = ft.Colors.ON_SURFACE_VARIANT
        self.caregiver_card.bgcolor = ft.Colors.ON_SURFACE_VARIANT
        self.patient_card.border = None
        self.caregiver_card.border = None
        
        selected_border = ft.border.all(4, ft.Colors.PRIMARY)

        if role == "patient":
            self.patient_card.bgcolor = ft.Colors.PRIMARY_CONTAINER
            self.patient_card.border = selected_border
        else:
            self.caregiver_card.bgcolor = ft.Colors.PRIMARY_CONTAINER
            self.caregiver_card.border = selected_border
            
        self.continue_button.visible = True
        self.update() 

    # go_to_login (sem mudanças)
    def go_to_login(self, e):
        if self.selected_role:
            self.page.go(f"/login/{self.selected_role}")