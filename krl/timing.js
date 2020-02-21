
const Http = new XMLHttpRequest();

const queryURL = 'http://localhost:8080/sky/cloud/JgjBbVYcfXgydkuev76oKU/'



// USING JQUERY
function currentTemperature() {
    var text = "";
    Http.open("GET", queryURL + 'temperature_store/current_temperature');
    Http.send();

    Http.onreadystatechange = function () {
        if (this.readyState == 4 && this.status == 200) {

            var currTemp = JSON.parse(Http.responseText);

            text += "<li>" + "Temp: " + currTemp.temp + " Time: " + currTemp.timestamp + "</li>"

            document.getElementById("temperatures").innerHTML = text;
        }
    }
}


function loadTemperatures() {
    var text = "";

    Http.open("GET", queryURL + 'temperature_store/temperatures');
    Http.send();


    Http.onreadystatechange = function () {
        if (this.readyState == 4 && this.status == 200) {

            var myArr = JSON.parse(Http.responseText);

            for (i = 0; i < myArr.length; i++) {
                text += "<li>" + "Temp =" + myArr[i].temp +
                    "   Time: " + myArr[i].timestamp + "</li>";
            }

            document.getElementById("temperatures").innerHTML = text;
        }
    }
}

function loadViolations() {
    var text = "";

    Http.open("GET", queryURL + 'temperature_store/threshold_violations');
    Http.send();


    Http.onreadystatechange = function () {
        if (this.readyState == 4 && this.status == 200) {

            var myArr = JSON.parse(Http.responseText);

            for (i = 0; i < myArr.length; i++) {
                text += "<li>" + "Temp =" + myArr[i].temp +
                    "   Time: " + myArr[i].timestamp + "</li>";
            }

            document.getElementById("temperatures").innerHTML = text;
        }
    }
}
function getInformation(){
    var text = "";

    Http.open("GET", queryURL + 'sensor_profile/getInfo');
    Http.send();
    Http.onreadystatechange = function () {
        if (this.readyState == 4 && this.status == 200) {

            var myArr = JSON.parse(Http.responseText);
            console.log(myArr)
            document.getElementById("info").innerHTML = myArr;
        }
    }
}


const eventURL = 'http://localhost:8080/sky/event/JgjBbVYcfXgydkuev76oKU/0000/'



function updateProfile() {
    let formData = new FormData(document.forms.person);

    var name = document.forms["myForm"]["name"].value;
    var location = document.forms["myForm"]["location"].value;
    var threshold = document.forms["myForm"]["threshold"].value;
    var toNotify = document.forms["myForm"]["toNotify"].value;

    // add one more field
    Http.open("POST", eventURL + 'sensor/profile_update?name=' + name + '&location=' + location + '&threshold=' + threshold + '&toNotify=' + toNotify, true);
    Http.send();

    Http.onload = () => alert(Http.response);
    return true
}