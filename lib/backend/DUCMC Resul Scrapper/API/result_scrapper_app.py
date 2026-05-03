import sys
sys.stdout.reconfigure(encoding='utf-8')

from fastapi import FastAPI
from datetime import datetime
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import Select, WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import re

app = FastAPI()


# ---------------- HEALTH CHECK ----------------
@app.get("/")
def health_check():
    return {
        "status": "ok",
        "service": "DUCMC Scraper API",
        "time": datetime.utcnow().isoformat()
    }


# ---------------- LIGHTWEIGHT PING ----------------
@app.get("/ping")
def ping():
    return {"message": "pong"}


# ---------------- SCRAPER FUNCTION ----------------
def scrape_result(reg_no, exam_id, sess_id):

    options = webdriver.ChromeOptions()
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")

    driver = webdriver.Chrome(options=options)
    wait = WebDriverWait(driver, 30)

    try:
        driver.get("https://ducmc.du.ac.bd/result.php")

        # -------- FORM FILL --------
        driver.find_element(By.ID, "reg_no").send_keys(reg_no)

        Select(driver.find_element(By.ID, "pro_id")).select_by_value("14")
        Select(driver.find_element(By.ID, "sess_id")).select_by_value(sess_id)

        wait.until(lambda d: len(Select(d.find_element(By.ID, "exam_id")).options) > 1)
        Select(driver.find_element(By.ID, "exam_id")).select_by_value(exam_id)

        driver.find_element(By.XPATH, "//button[@type='submit']").click()

        # -------- WAIT FOR RESULT --------
        wait.until(
            EC.presence_of_element_located(
                (By.XPATH, "//*[contains(text(),'CGPA') or contains(text(),'GPA')]")
            )
        )

        # -------- EXTRACT NAME --------
        try:
            name = driver.find_element(
                By.XPATH,
                "//th[contains(text(),\"Student's Name\")]/following-sibling::td"
            ).text.strip()
        except:
            name = None

        # -------- GET FULL TEXT --------
        text = driver.find_element(By.TAG_NAME, "body").text

        # -------- GPA / CGPA --------
        gpa = re.search(r"GPA:\s*([0-9.]+)", text)
        cgpa = re.search(r"CGPA:\s*([0-9.]+)", text)

        # -------- SUBJECTS --------
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

        return {
            "reg_no": reg_no,
            "name": name,
            "gpa": gpa.group(1) if gpa else None,
            "cgpa": cgpa.group(1) if cgpa else None,
            "subjects": subjects
        }

    except Exception as e:
        return {
            "error": str(e)
        }

    finally:
        driver.quit()


# ---------------- API ENDPOINT ----------------
@app.get("/result")
def get_result(reg_no: str, exam_id: str, sess_id: str):
    return scrape_result(reg_no, exam_id, sess_id)