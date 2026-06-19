const start_btn = document.querySelector(".start_btn button"),
    info_box = document.querySelector(".info_box"),
    exit_btn = info_box.querySelector(".buttons .quit"),
    continue_btn = info_box.querySelector(".buttons .restart"),
    quiz_box = document.querySelector(".quiz_box"),
    result_box = document.querySelector(".result_box"),
    option_list = document.querySelector(".option_list"),
    time_line = document.querySelector("header .time_line"),
    time_text = document.querySelector(".timer .time_left_txt"),
    timeCount = document.querySelector(".timer .timer_sec"),
    next_btn = document.querySelector("footer .next_btn"),
    bottom_ques_counter = document.querySelector("footer .total_que"),
    quit_quiz = result_box.querySelector(".buttons .quit"),
    quizContainer = document.querySelector(".quiz-container");

let timeValue = 15,
    que_count = 0,
    que_numb = 1,
    userScore = 0,
    counter,
    counterLine,
    widthValue = 0,
    questions = [],
    quizStarted = false;
((tickIconTag = '<div class="icon tick"><i class="fas fa-check"></i></div>'), (crossIconTag = '<div class="icon cross"><i class="fas fa-times"></i></div>'));

const showResult = () => {
    quiz_box.style.display = "none";
    result_box.style.display = "flex";
    quiz_box.classList.remove("activeQuiz");
    result_box.classList.add("activeResult");
    const scoreText = result_box.querySelector(".score_text");
    let scoreTag = `<span>and you got <p>${userScore}</p> out of <p>${questions.length}</p></span>`;
    scoreText.innerHTML = scoreTag;
};

const showQuestions = (index) => {
    const que_text = document.querySelector(".que_text");
    let question = questions[index];
    let que_tag = `<span>${question.numb}. ${question.question}</span>`;
    let option_tag = question.options.map((option, idx) => `<div class="option"><span>${option}</span></div>`).join("");
    que_text.innerHTML = que_tag;
    option_list.innerHTML = option_tag;
    const options = option_list.querySelectorAll(".option");
    options.forEach((option, idx) => {
        option.onclick = () => optionSelected(option, question.answer);
    });
};

const optionSelected = (option, correctAnswer) => {
    clearInterval(counter);
    clearInterval(counterLine);
    let selectedOptionText = option.textContent;
    let allOptions = option_list.querySelectorAll(".option");
    allOptions.forEach((opt) => opt.classList.add("disabled"));
    if (selectedOptionText === correctAnswer) {
        userScore += 1;
        option.classList.add("correct");
        option.insertAdjacentHTML("beforeend", tickIconTag);
    } else {
        option.classList.add("incorrect");
        option.insertAdjacentHTML("beforeend", crossIconTag);
        allOptions.forEach((opt) => {
            if (opt.textContent === correctAnswer) {
                opt.classList.add("correct");
                opt.insertAdjacentHTML("beforeend", tickIconTag);
            }
        });
    }
    if (que_count < questions.length - 1) {
        next_btn.classList.add("show");
    } else {
        showResult();
    }
};

const queCounter = (index) => {
    let totalQueCounTag = `<span><p>${index}</p> of <p>${questions.length}</p> Questions</span>`;
    bottom_ques_counter.innerHTML = totalQueCounTag;
};

const startTimer = (time) => {
    counter = setInterval(timer, 1000);
    function timer() {
        timeCount.textContent = time;
        time--;
        if (time < 9) {
            let addZero = timeCount.textContent;
            timeCount.textContent = "0" + addZero;
        }
        if (time < 0) {
            clearInterval(counter);
            time_text.textContent = "Time Off";
            const allOptions = option_list.children.length;
            let correcAns = questions[que_count].answer;
            for (i = 0; i < allOptions; i++) {
                if (option_list.children[i].textContent == correcAns) {
                    option_list.children[i].setAttribute("class", "option correct");
                    option_list.children[i].insertAdjacentHTML("beforeend", tickIconTag);
                    console.log("Time Off: Auto selected correct answer.");
                }
            }
            for (i = 0; i < allOptions; i++) {
                option_list.children[i].classList.add("disabled");
            }
            next_btn.classList.add("show");
        }
    }
};

const startTimerLine = (time) => {
    counterLine = setInterval(timer, 29);
    function timer() {
        time += 1;
        time_line.style.width = time + "px";
        if (time > 549) {
            clearInterval(counterLine);
        }
    }
};

const resetTimerAndLine = () => {
    clearInterval(counter);
    clearInterval(counterLine);
    startTimer(timeValue);
    startTimerLine(widthValue);
};

const setupQuizGame = (questionsData, timeForQuiz) => {
    quiz_box.classList.add("activeQuiz");
    result_box.classList.remove("activeResult");
    que_count = 0;
    que_numb = 1;
    userScore = 0;
    widthValue = 0;
    showQuestions(que_count);
    queCounter(que_numb);
    startTimer(timeForQuiz);
    startTimerLine(0);
};

const resetQuizUI = () => {
    start_btn.parentElement.style.display = "none";
    info_box.style.display = "none";
    quiz_box.style.display = "none";
    result_box.style.display = "none";
    quizStarted = false;
};

start_btn.onclick = () => {
    start_btn.parentElement.style.display = "none";
    info_box.classList.add("activeInfo");
    info_box.style.display = "flex";
};

continue_btn.onclick = () => {
    info_box.style.display = "none";
    quiz_box.style.display = "flex";
    setupQuizGame(questions, timeValue);
};

exit_btn.onclick = () => {
    hEvent("exitQuiz", {});
    resetQuizUI();
};

quit_quiz.onclick = () => {
    hEvent("quitQuiz", { score: userScore });
    resetQuizUI();
};

next_btn.onclick = () => {
    if (que_count < questions.length - 1) {
        que_count++;
        que_numb++;
        showQuestions(que_count);
        queCounter(que_numb);
        resetTimerAndLine();
        next_btn.classList.remove("show");
    } else {
        clearInterval(counter);
        clearInterval(counterLine);
        showResult();
    }
};

document.addEventListener("keydown", (event) => {
    if (!quizStarted) return;
    if (event.key === "Escape") {
        hEvent("closeQuiz", {});
        resetQuizUI();
    }
});

window.addEventListener("message", (event) => {
    const msg = event.data;
    if (!msg || !msg.name) return;
    const data = (msg.args && msg.args[0]) || {};
    if (msg.name === "startQuiz") {
        questions = data.questions;
        timeValue = data.timer || 15;
        quizContainer.style.display = "flex";
        start_btn.parentElement.style.display = "flex";
        quizStarted = true;
    }
});
