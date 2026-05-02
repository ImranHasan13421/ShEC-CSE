import sys
sys.stdout.reconfigure(encoding='utf-8')

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import Select, WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import re


def get_result(reg_no):

    options = webdriver.ChromeOptions()
    options.add_argument("--headless=new")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")

    driver = webdriver.Chrome(options=options)
    wait = WebDriverWait(driver, 30)

    driver.get("https://ducmc.du.ac.bd/result.php")

    # ---------------- FORM ----------------
    driver.find_element(By.ID, "reg_no").send_keys(reg_no)

    Select(driver.find_element(By.ID, "pro_id")).select_by_value("14")
    Select(driver.find_element(By.ID, "sess_id")).select_by_value("21")

    wait.until(lambda d: len(Select(d.find_element(By.ID, "exam_id")).options) > 1)
    Select(driver.find_element(By.ID, "exam_id")).select_by_value("1387")

    driver.find_element(By.XPATH, "//button[@type='submit']").click()

    wait.until(
        EC.presence_of_element_located(
            (By.XPATH, "//*[contains(text(),'CGPA') or contains(text(),'GPA')]")
        )
    )

    # ---------------- RAW TEXT ----------------
    text = driver.find_element(By.TAG_NAME, "body").text

    # ---------------- EXTRACT GPA / CGPA ----------------
    gpa = re.search(r"GPA:\s*([0-9.]+)", text)
    cgpa = re.search(r"CGPA:\s*([0-9.]+)", text)

    status = "Promoted" if "Promoted" in text else "Not Found"

    # ---------------- SUBJECTS ----------------
    subjects = []

    rows = driver.find_elements(By.TAG_NAME, "tr")

    for row in rows:
        cols = row.find_elements(By.TAG_NAME, "td")

        if len(cols) == 5 and cols[0].text.strip().isdigit():
            subjects.append({
                "code": cols[1].text.strip(),
                "name": cols[2].text.strip(),
                "grade": cols[3].text.strip(),
                "point": cols[4].text.strip()
            })

    driver.quit()

    # ---------------- CLEAN OUTPUT ----------------
    return {
        "reg_no": reg_no,
        "status": status,
        "gpa": gpa.group(1) if gpa else None,
        "cgpa": cgpa.group(1) if cgpa else None,
        "subjects": subjects
    }


# ---------------- TEST ----------------
data = get_result("566")

print("\n===== CLEAN RESULT =====\n")

print("Status:", data["status"])
print("GPA:", data["gpa"])
print("CGPA:", data["cgpa"])

print("\nSubjects:")
for s in data["subjects"]:
    print(f"{s['code']} | {s['name']} | {s['grade']} | {s['point']}")

print("\nTotal Subjects:", len(data["subjects"]))