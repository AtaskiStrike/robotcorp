*** Settings ***
Documentation    Orders robots from RobotSpareBin Industries Inc.
...              Saves the order HTML receipt as a PDF file.
...              Saves the screenshot of the ordered robot.
...              Embeds the screenshot of the robot to the PDF receipt.
...              Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Robocorp.Vault
Library    RPA.Dialogs

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    information
    Open Available Browser    ${secret}[url]
Close the annoying modal
    Click Button    class:btn-dark

Input form dialog
    Add heading       Gestor de descarga de archivos
    Add text input    ruta
    ...    label=Archivo CSV:
    ...    placeholder=Ingrese en enlace para descargar archivo
    ...    rows=3
    ${result}=    Run dialog
    RETURN  ${result}
Get orders
    ${result}=    Input form dialog
    Download    ${result.ruta}    overwrite=True
    ${table}=    Read table from CSV    orders.csv    header=True
    RETURN    ${table}

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    address    ${order}[Address]
    Input Text    class:form-control    ${order}[Legs]

Preview the robot
    Click Button    preview

Submit the order
    Click Button When Visible    order
    Assert order

Assert order
    Wait Until Page Contains Element    receipt

Go to order another robot
    Click Button    order-another

Store the receipt as a PDF file
    [Arguments]    ${name}
    Wait Until Element Is Visible    id:order-completion
    ${receipt}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}receipts${/}${name}.pdf

Take a screenshot of the robot
    [Arguments]    ${name}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}screenshot${/}${name}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${name}
    Open Pdf    ${OUTPUT_DIR}${/}receipts${/}${name}.pdf
    ${files}=    Create List
    ...    ${OUTPUT_DIR}${/}screenshot${/}${name}.png:align=center
    Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}receipts${/}${name}.pdf    append=True
    Close Pdf

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}receipts
    ...    ${zip_file_name}

Close browser availe
    Close Browser
*** Tasks ***

Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Preview the robot
        Wait Until Keyword Succeeds    4x    4s    Submit the order
        Store the receipt as a PDF file    ${order}[Order number]
        Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${order}[Order number]
        Go to order another robot
    END
    Create ZIP package from PDF files
    [Teardown]    Close browser availe
    Log    Done.
