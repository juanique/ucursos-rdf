from xml.etree import ElementTree

class ElementWrapper(object):

    def __init__(self, file_or_element):
        if isinstance(file_or_element, basestring):
            with file(file_or_element) as f:
                self.element = ElementTree.fromstring(f.read())
        else:
            self.element = file_or_element

    def __getattr__(self, name):
        matches = self.element.iterfind(name)

        for match in matches:
            node = match

        if len(node) == 0:
            return node.text
        else:
            return ElementWrapper(node)

    def all(self, name):
        matches = self.element.iterfind(name)
        out = []

        for match in matches:
            out.append(ElementWrapper(match))

        return out
